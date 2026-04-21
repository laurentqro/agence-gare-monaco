class PropertyTranslationJob < ApplicationJob
  queue_as :default

  retry_on RubyLLM::RateLimitError,
           RubyLLM::ServerError,
           RubyLLM::ServiceUnavailableError,
           RubyLLM::OverloadedError,
           Net::OpenTimeout,
           JSON::ParserError,
           wait: :polynomially_longer, attempts: 5

  discard_on RubyLLM::UnauthorizedError,
             RubyLLM::ForbiddenError,
             RubyLLM::BadRequestError,
             RubyLLM::PaymentRequiredError,
             RubyLLM::ContextLengthExceededError do |job, error|
    job.record_failure(error)
  end

  def perform(property_id)
    @property = Property.find_by(id: property_id)
    return unless @property

    PropertyTranslator.new(@property).translate!
  end

  def record_failure(error)
    return unless @property

    status = (@property.translations_status || {}).dup
    status["_error"] = {
      "class" => error.class.name,
      "message" => error.message.to_s[0, 500],
      "failed_at" => Time.current.iso8601
    }
    @property.update_columns(translations_status: status)
  end
end
