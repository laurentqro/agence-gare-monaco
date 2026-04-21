class PropertyTranslationJob < ApplicationJob
  queue_as :default

  # Transient failures — retry with backoff.
  retry_on RubyLLM::RateLimitError,
           RubyLLM::ServerError,
           RubyLLM::ServiceUnavailableError,
           RubyLLM::OverloadedError,
           Net::OpenTimeout,
           JSON::ParserError,
           wait: :polynomially_longer, attempts: 5

  # Permanent failures — no point retrying; drop and let the caller notice.
  discard_on RubyLLM::UnauthorizedError,
             RubyLLM::ForbiddenError,
             RubyLLM::BadRequestError,
             RubyLLM::PaymentRequiredError,
             RubyLLM::ContextLengthExceededError

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property

    PropertyTranslator.new(property).translate!
  end
end
