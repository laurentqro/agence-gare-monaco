class PropertyTranslationJob < ApplicationJob
  queue_as :default

  # Record the failure when retries run out, not just on discard. Without this
  # the job dies leaving translation_source_hash nil and no marker, so the
  # 5-minute sync re-enqueues a paid LLM call every tick forever — a sustained
  # outage would do that catalogue-wide. Re-raise so the job still lands in
  # Solid Queue's failed set for visibility.
  retry_on RubyLLM::RateLimitError,
           RubyLLM::ServerError,
           RubyLLM::ServiceUnavailableError,
           RubyLLM::OverloadedError,
           Net::OpenTimeout,
           JSON::ParserError,
           wait: :polynomially_longer, attempts: 5 do |job, error|
    job.record_failure(error)
    raise error
  end

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
    # update_columns bypasses callbacks on purpose: we're on the failure path
    # and must not re-trigger enqueue_post_save_jobs! and another translation.
    @property.update_columns(translations_status: status)
  end
end
