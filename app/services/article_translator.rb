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
    new_hash = @article.current_fr_hash

    if new_hash == @article.translation_source_hash
      Rails.logger.info("[ArticleTranslator] article=#{@article.id} skipped (source unchanged)")
      return
    end

    started_at = Time.current
    Rails.logger.info(
      "[ArticleTranslator] article=#{@article.id} starting model=#{self.class.model} " \
      "fr_title_chars=#{fr_title.length} fr_body_chars=#{fr_body.length}"
    )

    body_required = fr_body.strip.present?
    meta_required = @article.meta_description_for(:fr).present?
    LOCALES.each do |locale|
      translate_locale!(locale, new_hash, body_required, meta_required)
    end

    finalize!(new_hash)

    duration = (Time.current - started_at).round(2)
    Rails.logger.info("[ArticleTranslator] article=#{@article.id} completed in=#{duration}s")
  end

  private

  def translate_locale!(locale, new_hash, body_required, meta_required)
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

    fields = parse_locale(response.content, locale, body_required, meta_required)
    apply_locale!(locale, fields, new_hash)
  end

  def locale_already_current?(locale, new_hash)
    entry = (@article.translations_status || {})[locale]
    entry.is_a?(Hash) && entry["source_hash"] == new_hash && entry["translated_at"].present?
  end

  def parse_locale(content, locale, body_required, meta_required)
    raise BlankTranslation, "Response is not a hash for #{locale}: #{content.inspect}" unless content.is_a?(Hash)

    fields = { title: require_string!(content["title"], "title", locale) }
    fields[:body] = require_string!(content["body"], "body", locale) if body_required
    fields[:meta_description] = require_string!(content["meta_description"], "meta_description", locale) if meta_required
    fields
  end

  def require_string!(value, field, locale)
    raise BlankTranslation, "Non-string #{field} for #{locale}: #{value.inspect}" unless value.is_a?(String)
    raise BlankTranslation, "Blank #{field} for #{locale}" if value.strip.empty?
    value
  end

  def apply_locale!(locale, fields, new_hash)
    with_locked_row do |row|
      title = (row.title || {}).dup
      body = (row.body || {}).dup
      meta = (row.meta_description || {}).dup
      slugs = (row.slugs || {}).dup
      status = (row.translations_status || {}).dup

      title[locale] = fields[:title]
      body[locale] = fields[:body] if fields.key?(:body)
      meta[locale] = fields[:meta_description] if fields.key?(:meta_description)

      # Mint a per-locale slug from the new translation (SEO audit 0.2), but only
      # when this locale has none yet: slugs are frozen, so a later FR edit that
      # re-translates the title must not move an already-indexed URL.
      if slugs[locale].blank?
        localized_slug = fields[:title].parameterize(locale: locale.to_sym)
        slugs[locale] = localized_slug if localized_slug.present?
      end

      status[locale] = {
        "translated_at" => Time.current.iso8601,
        "source_hash" => new_hash
      }

      { title: title, body: body, meta_description: meta, slugs: slugs, translations_status: status }
    end
  end

  def finalize!(new_hash)
    with_locked_row do |row|
      status = (row.translations_status || {}).dup
      status.delete("_error")
      { translations_status: status, translation_source_hash: new_hash }
    end
  end

  # Yields a freshly-locked row; takes the columns hash returned by the block
  # and writes it (plus an updated_at bump) inside the same transaction. The
  # row-lock + fresh re-read protects merges from concurrent FR edits.
  def with_locked_row
    Article.transaction do
      row = Article.lock.find(@article.id)
      columns = yield(row)
      row.update_columns(columns.merge(updated_at: Time.current))
    end
  end
end
