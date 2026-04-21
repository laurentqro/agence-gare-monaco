class PropertyTranslator
  DEFAULT_MODEL = "claude-sonnet-4-6".freeze

  # Single source of truth for the non-FR locales the translator fills and
  # their human-readable names for the LLM prompt. Adding a locale to the app
  # means adding a row here — keys must match I18n.available_locales minus :fr
  # (enforced by a test, so booting prod never silently drops a language).
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
    fr_title = @property.title_for(:fr)
    fr_description = @property.description_for(:fr)
    new_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_description}")
    expected_hash = @property.translation_source_hash
    return if new_hash == expected_hash

    builder = PromptBuilder.new(@property)
    chat = RubyLLM.chat(model: self.class.model)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    log_usage(response)

    translations = parse(response.content, fr_description)
    return unless apply_translations!(translations, new_hash, expected_hash)

    PropertyBrochureGenerationJob.perform_later(@property.id)
  end

  private

  def log_usage(response)
    Rails.logger.info(
      "[PropertyTranslator] property=#{@property.id} model=#{self.class.model} " \
      "in=#{response.input_tokens} out=#{response.output_tokens}"
    )
  end

  def parse(content, fr_description)
    raise BlankTranslation, "Response is not a hash: #{content.inspect}" unless content.is_a?(Hash)

    parsed = {}
    LOCALES.each do |locale|
      title = content["title_#{locale}"].to_s
      description = content["description_#{locale}"].to_s

      raise BlankTranslation, "Blank title for #{locale}" if title.strip.empty?

      if fr_description.strip.empty?
        parsed[locale] = { title: title }
      else
        raise BlankTranslation, "Blank description for #{locale}" if description.strip.empty?
        parsed[locale] = { title: title, description: description }
      end
    end
    parsed
  end

  # Returns true if the row was updated, false if a concurrent worker raced
  # ahead (its translations stay; ours are stale by definition).
  def apply_translations!(translations, new_hash, expected_hash)
    title = (@property.title || {}).dup
    description = (@property.description || {}).dup
    status = (@property.translations_status || {}).dup
    timestamp = Time.current.iso8601

    translations.each do |locale, fields|
      title[locale] = fields[:title]
      description[locale] = fields[:description] if fields.key?(:description)
      status[locale] = { "translated_at" => timestamp }
    end

    rows = Property.where(id: @property.id, translation_source_hash: expected_hash).update_all(
      title: title,
      description: description,
      translations_status: status,
      translation_source_hash: new_hash,
      updated_at: Time.current
    )
    rows.positive?
  end
end
