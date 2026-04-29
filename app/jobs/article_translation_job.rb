class ArticleTranslationJob < ApplicationJob
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

  def perform(article_id)
    @article = Article.find_by(id: article_id)
    return unless @article

    ArticleTranslator.new(@article).translate!
  end

  def record_failure(error)
    return unless @article

    status = (@article.translations_status || {}).dup
    status["_error"] = {
      "class" => error.class.name,
      "message" => error.message.to_s[0, 500],
      "failed_at" => Time.current.iso8601
    }
    # update_columns bypasses callbacks on purpose: we're on the failure path
    # and must not re-trigger enqueue_post_save_jobs! and another translation.
    @article.update_columns(translations_status: status)
  end
end
