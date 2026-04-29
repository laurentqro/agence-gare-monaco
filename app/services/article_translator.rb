class ArticleTranslator
  DEFAULT_MODEL = "claude-sonnet-4-6".freeze

  LOCALE_NAMES = {
    "en" => "English",
    "it" => "Italian",
    "de" => "German",
    "sv" => "Swedish",
    "no" => "Norwegian (Bokmål)",
    "da" => "Danish",
    "fi" => "Finnish",
    "ru" => "Russian"
  }.freeze

  LOCALES = LOCALE_NAMES.keys.freeze

  def self.model
    Rails.configuration.x.translator_model.presence || DEFAULT_MODEL
  end

  class BlankTranslation < StandardError; end

  def initialize(article)
    @article = article
  end

  def translate!
    fr_title = @article.title_for(:fr)
    fr_body = @article.body_for(:fr)
    new_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_body}")
    expected_hash = @article.translation_source_hash
    return if new_hash == expected_hash

    builder = PromptBuilder.new(@article)
    chat = RubyLLM.chat(model: self.class.model)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    log_usage(response)

    translations = parse(response.content, fr_body)
    apply_translations!(translations, new_hash, expected_hash)
  end

  private

  def log_usage(response)
    Rails.logger.info(
      "[ArticleTranslator] article=#{@article.id} model=#{self.class.model} " \
      "in=#{response.input_tokens} out=#{response.output_tokens}"
    )
  end

  def parse(content, fr_body)
    raise BlankTranslation, "Response is not a hash: #{content.inspect}" unless content.is_a?(Hash)

    parsed = {}
    LOCALES.each do |locale|
      title = require_string!(content["title_#{locale}"], "title", locale)

      if fr_body.strip.empty?
        parsed[locale] = { title: title }
      else
        body = require_string!(content["body_#{locale}"], "body", locale)
        parsed[locale] = { title: title, body: body }
      end
    end
    parsed
  end

  def require_string!(value, field, locale)
    raise BlankTranslation, "Non-string #{field} for #{locale}: #{value.inspect}" unless value.is_a?(String)
    raise BlankTranslation, "Blank #{field} for #{locale}" if value.strip.empty?
    value
  end

  # Returns false if a concurrent worker raced ahead — its translations stay,
  # ours are stale by definition.
  def apply_translations!(translations, new_hash, expected_hash)
    title = (@article.title || {}).dup
    body = (@article.body || {}).dup
    status = (@article.translations_status || {}).dup
    status.delete("_error")
    timestamp = Time.current.iso8601

    translations.each do |locale, fields|
      title[locale] = fields[:title]
      body[locale] = fields[:body] if fields.key?(:body)
      status[locale] = { "translated_at" => timestamp }
    end

    rows = Article.where(id: @article.id, translation_source_hash: expected_hash).update_all(
      title: title,
      body: body,
      translations_status: status,
      translation_source_hash: new_hash,
      updated_at: Time.current
    )
    rows.positive?
  end
end
