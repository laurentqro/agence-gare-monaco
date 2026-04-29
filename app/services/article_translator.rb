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

    if new_hash == @article.translation_source_hash
      Rails.logger.info("[ArticleTranslator] article=#{@article.id} skipped (source unchanged)")
      return
    end

    started_at = Time.current
    Rails.logger.info(
      "[ArticleTranslator] article=#{@article.id} starting model=#{self.class.model} " \
      "fr_title_chars=#{fr_title.length} fr_body_chars=#{fr_body.length}"
    )

    LOCALES.each do |locale|
      translate_locale!(locale, new_hash, fr_body)
    end

    finalize!(new_hash)

    duration = (Time.current - started_at).round(2)
    Rails.logger.info("[ArticleTranslator] article=#{@article.id} completed in=#{duration}s")
  end

  private

  def translate_locale!(locale, new_hash, fr_body)
    if locale_already_current?(locale, new_hash)
      Rails.logger.info("[ArticleTranslator] article=#{@article.id} locale=#{locale} skipped (already translated for current source)")
      return
    end

    builder = PromptBuilder.new(@article, locale)
    chat = RubyLLM.chat(model: self.class.model)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    Rails.logger.info(
      "[ArticleTranslator] article=#{@article.id} llm_response locale=#{locale} model=#{self.class.model} " \
      "in=#{response.input_tokens} out=#{response.output_tokens}"
    )

    fields = parse_locale(response.content, locale, fr_body)
    apply_locale!(locale, fields, new_hash)
  end

  def locale_already_current?(locale, new_hash)
    entry = (@article.translations_status || {})[locale]
    entry.is_a?(Hash) && entry["source_hash"] == new_hash && entry["translated_at"].present?
  end

  def parse_locale(content, locale, fr_body)
    raise BlankTranslation, "Response is not a hash for #{locale}: #{content.inspect}" unless content.is_a?(Hash)

    title = require_string!(content["title"], "title", locale)
    if fr_body.strip.empty?
      { title: title }
    else
      body = require_string!(content["body"], "body", locale)
      { title: title, body: body }
    end
  end

  def require_string!(value, field, locale)
    raise BlankTranslation, "Non-string #{field} for #{locale}: #{value.inspect}" unless value.is_a?(String)
    raise BlankTranslation, "Blank #{field} for #{locale}" if value.strip.empty?
    value
  end

  # Persist one locale's translation. We freshly read the row inside the
  # transaction so we don't clobber a concurrent FR edit (admin saving the FR
  # text mid-loop). After this row-lock+merge, the only way two writers can
  # collide is if both translate the same locale at the same instant — and the
  # source-hash skip at the top of translate_locale! handles that on retry.
  def apply_locale!(locale, fields, new_hash)
    Article.transaction do
      row = Article.lock.find(@article.id)
      title = (row.title || {}).dup
      body = (row.body || {}).dup
      status = (row.translations_status || {}).dup

      title[locale] = fields[:title]
      body[locale] = fields[:body] if fields.key?(:body)
      status[locale] = {
        "translated_at" => Time.current.iso8601,
        "source_hash" => new_hash
      }

      row.update_columns(
        title: title,
        body: body,
        translations_status: status,
        updated_at: Time.current
      )
    end
  end

  def finalize!(new_hash)
    Article.transaction do
      row = Article.lock.find(@article.id)
      status = (row.translations_status || {}).dup
      status.delete("_error")
      row.update_columns(
        translations_status: status,
        translation_source_hash: new_hash,
        updated_at: Time.current
      )
    end
  end
end
