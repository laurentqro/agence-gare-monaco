class PropertyTranslationJob < ApplicationJob
  queue_as :default

  # Record the failure when retries run out, not just on discard. The marker
  # does not stop anything: the sync keeps re-enqueuing an untranslated
  # property regardless, deliberately, because the causes are transient or
  # operator-fixable and a permanently untranslated property is worse than the
  # retry cost. It exists purely for visibility: the admin failure banner,
  # Property.translation_failed, and translations:retry_failed all read it.
  # Re-raise so the job still lands in Solid Queue's failed set too.
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
