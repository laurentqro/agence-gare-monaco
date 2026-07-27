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
    fr_title = @property.title_for(:fr)
    fr_intro = @property.intro_for(:fr)
    fr_description = @property.description_for(:fr)
    new_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_intro}\n#{fr_description}")
    expected_hash = @property.translation_source_hash
    return if new_hash == expected_hash

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
    # Clear any recorded hard failure: this run succeeded. enqueue_post_save_jobs!
    # refuses to retry while an "_error" is present, so a stale marker would block
    # every future retranslation of this property.
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
