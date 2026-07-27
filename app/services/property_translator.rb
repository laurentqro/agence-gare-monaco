class PropertyTranslator
  DEFAULT_MODEL = "claude-sonnet-4-6".freeze

  # Keys must match I18n.available_locales minus :fr — enforced by a test so
  # adding a locale to config/application.rb without naming it fails loudly.
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

  def initialize(property)
    @property = property
  end

  def translate!
    fr_intro = @property.intro_for(:fr)
    fr_description = @property.description_for(:fr)
    # Property#current_fr_hash is the single definition of the source digest;
    # the admin staleness chips compare against the same value.
    new_hash = @property.current_fr_hash
    expected_hash = @property.translation_source_hash
    if new_hash == expected_hash
      # The stored hash covers the current FR text, so the translation is
      # provably current and any recorded failure is stale (the FR text flapped
      # back to its pre-failure value). Without this, the admin failure banner
      # would stay up forever and an operator would pay for a full
      # retranslation of already-correct content just to dismiss it.
      clear_stale_failure!
      return
    end

    builder = PromptBuilder.new(@property)
    chat = RubyLLM.chat(model: self.class.model)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    log_usage(response)

    translations = parse(response.content, fr_intro, fr_description)
    return unless apply_translations!(translations, new_hash, expected_hash)

    PropertyBrochureGenerationJob.perform_later(@property.id)
  end

  private

  # update_columns on purpose: nothing about the content changed, so callbacks
  # and updated_at (the sitemap's lastmod) must stay untouched.
  def clear_stale_failure!
    return unless @property.translation_error

    status = @property.translations_status.dup
    status.delete("_error")
    @property.update_columns(translations_status: status)
  end

  def log_usage(response)
    Rails.logger.info(
      "[PropertyTranslator] property=#{@property.id} model=#{self.class.model} " \
      "in=#{response.input_tokens} out=#{response.output_tokens}"
    )
  end

  def parse(content, fr_intro, fr_description)
    raise BlankTranslation, "Response is not a hash: #{content.inspect}" unless content.is_a?(Hash)

    parsed = {}
    LOCALES.each do |locale|
      fields = { title: require_string!(content["title_#{locale}"], "title", locale) }

      unless fr_intro.strip.empty?
        fields[:intro] = require_string!(content["intro_#{locale}"], "intro", locale)
      end

      unless fr_description.strip.empty?
        fields[:description] = require_string!(content["description_#{locale}"], "description", locale)
      end

      parsed[locale] = fields
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
    title = (@property.title || {}).dup
    intro = (@property.intro || {}).dup
    description = (@property.description || {}).dup
    status = (@property.translations_status || {}).dup
    # Clear any recorded hard failure: this run succeeded, so the marker is
    # stale. It is a visibility signal (admin banner, Property.translation_failed),
    # not a retry gate, and it must not outlive the failure it reports.
    status.delete("_error")
    timestamp = Time.current.iso8601

    translations.each do |locale, fields|
      title[locale] = fields[:title]
      intro[locale] = fields[:intro] if fields.key?(:intro)
      description[locale] = fields[:description] if fields.key?(:description)
      status[locale] = { "translated_at" => timestamp }
    end

    rows = Property.where(id: @property.id, translation_source_hash: expected_hash).update_all(
      title: title,
      intro: intro,
      description: description,
      translations_status: status,
      translation_source_hash: new_hash,
      updated_at: Time.current
    )
    rows.positive?
  end
end
