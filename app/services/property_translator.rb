class PropertyTranslator
  MODEL = "claude-sonnet-4-6".freeze
  LOCALES = %w[en it de sv no da fi ru].freeze

  class BlankTranslation < StandardError; end

  def initialize(property)
    @property = property
  end

  def translate!
    fr_title = fr("title")
    fr_description = fr("description")
    hash = content_hash(fr_title, fr_description)
    expected_hash = @property.translation_source_hash
    return if hash == expected_hash

    builder = PromptBuilder.new(@property)
    chat = RubyLLM.chat(model: MODEL)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    log_usage(response)

    translations = parse(response.content, fr_description)
    applied = apply_translations!(translations, hash, expected_hash)
    return unless applied

    PropertyBrochureGenerationJob.perform_later(@property.id)
  end

  private

  def log_usage(response)
    input = response.respond_to?(:input_tokens) ? response.input_tokens : nil
    output = response.respond_to?(:output_tokens) ? response.output_tokens : nil
    Rails.logger.info("[PropertyTranslator] property=#{@property.id} model=#{MODEL} in=#{input} out=#{output}")
  end

  def fr(field)
    value = @property.public_send(field)
    value.is_a?(Hash) ? value["fr"].to_s : ""
  end

  def content_hash(title, description)
    Digest::SHA256.hexdigest("#{title}\n#{description}")
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

  # Guarded write: only applies translations if translation_source_hash is
  # still what we read at the start. If a concurrent worker beat us to it,
  # their result stands — our response is stale by definition.
  # Returns true if the row was updated, false if another worker raced ahead.
  def apply_translations!(translations, hash, expected_hash)
    current = Property.where(id: @property.id).limit(1).pluck(:title, :description, :translations_status).first
    return false unless current # row vanished

    title = current[0].is_a?(Hash) ? current[0].dup : {}
    description = current[1].is_a?(Hash) ? current[1].dup : {}
    status = current[2].is_a?(Hash) ? current[2].dup : {}
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
      translation_source_hash: hash,
      updated_at: Time.current
    )
    rows.positive?
  end
end
