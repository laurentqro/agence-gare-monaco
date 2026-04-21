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
             RubyLLM::ContextLengthExceededError do |job, error|
    job.record_failure(error)
  end

  def perform(property_id)
    @property_id = property_id
    property = Property.find_by(id: property_id)
    return unless property

    PropertyTranslator.new(property).translate!
  end

  def record_failure(error)
    property = Property.find_by(id: @property_id)
    return unless property

    status = property.translations_status.is_a?(Hash) ? property.translations_status.dup : {}
    status["_error"] = {
      "class" => error.class.name,
      "message" => error.message.to_s[0, 500],
      "failed_at" => Time.current.iso8601
    }
    property.update_columns(translations_status: status)
  end
end
