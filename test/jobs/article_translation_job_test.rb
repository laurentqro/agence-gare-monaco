require "test_helper"

class ArticleTranslationJobTest < ActiveJob::TestCase
  setup do
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    @article = Article.create!(
      title: { "fr" => "Titre" },
      body: { "fr" => "Corps de l'article." },
      slug: "titre",
      category: @category
    )
  end

  test "perform_later enqueues the job" do
    assert_enqueued_with(job: ArticleTranslationJob, args: [ @article.id ]) do
      ArticleTranslationJob.perform_later(@article.id)
    end
  end

  test "returns silently when article is deleted before perform" do
    assert_nothing_raised do
      ArticleTranslationJob.perform_now(9_999_999)
    end
  end

  test "invokes ArticleTranslator#translate! with the article" do
    received = nil
    fake_new = ->(article) {
      received = article
      Object.new.tap { |o| o.define_singleton_method(:translate!) { } }
    }
    SingletonStub.with(ArticleTranslator, :new, fake_new) do
      ArticleTranslationJob.perform_now(@article.id)
    end
    assert_equal @article.id, received.id
  end

  test "retry_on covers transient transport errors" do
    handled = ArticleTranslationJob.rescue_handlers.map(&:first)
    assert_includes handled, "RubyLLM::RateLimitError"
    assert_includes handled, "RubyLLM::ServerError"
    assert_includes handled, "RubyLLM::ServiceUnavailableError"
    assert_includes handled, "RubyLLM::OverloadedError"
    assert_includes handled, "Net::OpenTimeout"
    assert_includes handled, "JSON::ParserError"
  end

  test "retry_on covers BlankTranslation so a partial LLM response gets re-asked" do
    handled = ArticleTranslationJob.rescue_handlers.map(&:first)
    assert_includes handled, "ArticleTranslator::BlankTranslation"
  end

  test "discard_on covers permanent errors so they do not burn retries" do
    handled = ArticleTranslationJob.rescue_handlers.map(&:first)
    assert_includes handled, "RubyLLM::UnauthorizedError"
    assert_includes handled, "RubyLLM::ForbiddenError"
    assert_includes handled, "RubyLLM::BadRequestError"
    assert_includes handled, "RubyLLM::PaymentRequiredError"
    assert_includes handled, "RubyLLM::ContextLengthExceededError"
  end

  test "does not swallow the base RubyLLM::Error class" do
    handled = ArticleTranslationJob.rescue_handlers.map(&:first)
    refute_includes handled, "RubyLLM::Error"
  end

  test "records failure metadata when a permanent error discards the job" do
    raising_translator = ->(_article) {
      Object.new.tap do |t|
        t.define_singleton_method(:translate!) do
          raise RubyLLM::UnauthorizedError.new(nil, "Bad API key")
        end
      end
    }

    SingletonStub.with(ArticleTranslator, :new, raising_translator) do
      freeze_time do
        ArticleTranslationJob.perform_now(@article.id)
        @article.reload
        assert @article.translations_status["_error"].present?
        assert_equal "RubyLLM::UnauthorizedError", @article.translations_status["_error"]["class"]
        assert_match(/Bad API key/, @article.translations_status["_error"]["message"])
        assert_equal Time.current.iso8601, @article.translations_status["_error"]["failed_at"]
      end
    end
  end

  test "logs error class and message when a permanent error discards the job" do
    raising_translator = ->(_article) {
      Object.new.tap do |t|
        t.define_singleton_method(:translate!) do
          raise RubyLLM::UnauthorizedError.new(nil, "Bad API key")
        end
      end
    }

    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      SingletonStub.with(ArticleTranslator, :new, raising_translator) do
        ArticleTranslationJob.perform_now(@article.id)
      end
    ensure
      Rails.logger = original_logger
    end

    assert_match(/\[ArticleTranslationJob\] article=#{@article.id} discarded/, io.string)
    assert_match(/RubyLLM::UnauthorizedError/, io.string)
    assert_match(/Bad API key/, io.string)
  end

  test "logs missing-article no-op at info level" do
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      ArticleTranslationJob.perform_now(9_999_999)
    ensure
      Rails.logger = original_logger
    end
    assert_match(/\[ArticleTranslationJob\] article=9999999 not found/, io.string)
  end
end
