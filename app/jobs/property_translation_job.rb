class PropertyTranslationJob < ApplicationJob
  queue_as :default

  retry_on RubyLLM::Error, Net::OpenTimeout, JSON::ParserError, wait: :polynomially_longer, attempts: 5

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property

    PropertyTranslator.new(property).translate!
  end
end
