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
    return if hash == @property.translation_source_hash

    builder = PromptBuilder.new(@property)
    chat = RubyLLM.chat(model: MODEL)
      .with_instructions(builder.system_prompt)
      .with_schema(Schema)
    response = chat.ask(builder.user_prompt)

    translations = parse(response.content, fr_description)
    apply_translations!(translations, hash)

    PropertyBrochureGenerationJob.perform_later(@property.id)
  end

  private

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

  def apply_translations!(translations, hash)
    title = (@property.title.is_a?(Hash) ? @property.title.dup : {})
    description = (@property.description.is_a?(Hash) ? @property.description.dup : {})
    status = (@property.translations_status.is_a?(Hash) ? @property.translations_status.dup : {})
    timestamp = Time.current.iso8601

    translations.each do |locale, fields|
      title[locale] = fields[:title]
      description[locale] = fields[:description] if fields.key?(:description)
      status[locale] = { "translated_at" => timestamp }
    end

    @property.update_columns(
      title: title,
      description: description,
      translations_status: status,
      translation_source_hash: hash
    )
  end
end
