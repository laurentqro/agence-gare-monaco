require "test_helper"

class PropertyTranslationJobTest < ActiveJob::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-JOB-001",
      title: { "fr" => "Penthouse" },
      description: { "fr" => "Description française." },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
  end

  test "perform_later enqueues the job" do
    assert_enqueued_with(job: PropertyTranslationJob, args: [ @property.id ]) do
      PropertyTranslationJob.perform_later(@property.id)
    end
  end

  test "returns silently when property is deleted before perform" do
    assert_nothing_raised do
      PropertyTranslationJob.perform_now(9_999_999)
    end
  end

  test "invokes PropertyTranslator#translate! with the property" do
    received = nil
    PropertyTranslator.singleton_class.alias_method(:new_original, :new)
    PropertyTranslator.singleton_class.define_method(:new) do |property|
      received = property
      Object.new.tap { |o| o.define_singleton_method(:translate!) {} }
    end
    begin
      PropertyTranslationJob.perform_now(@property.id)
    ensure
      PropertyTranslator.singleton_class.alias_method(:new, :new_original)
      PropertyTranslator.singleton_class.remove_method(:new_original)
    end
    assert_equal @property.id, received.id
  end

  test "retry_on covers transient transport errors" do
    handled = PropertyTranslationJob.rescue_handlers.map(&:first)
    assert_includes handled, "RubyLLM::RateLimitError"
    assert_includes handled, "RubyLLM::ServerError"
    assert_includes handled, "RubyLLM::ServiceUnavailableError"
    assert_includes handled, "RubyLLM::OverloadedError"
    assert_includes handled, "Net::OpenTimeout"
    assert_includes handled, "JSON::ParserError"
  end

  test "discard_on covers permanent errors so they do not burn retries" do
    handled = PropertyTranslationJob.rescue_handlers.map(&:first)
    assert_includes handled, "RubyLLM::UnauthorizedError"
    assert_includes handled, "RubyLLM::ForbiddenError"
    assert_includes handled, "RubyLLM::BadRequestError"
    assert_includes handled, "RubyLLM::PaymentRequiredError"
    assert_includes handled, "RubyLLM::ContextLengthExceededError"
  end

  test "does not swallow the base RubyLLM::Error class (would hide unexpected errors)" do
    handled = PropertyTranslationJob.rescue_handlers.map(&:first)
    refute_includes handled, "RubyLLM::Error"
  end

  test "records failure metadata on the property when a permanent error discards the job" do
    PropertyTranslator.singleton_class.alias_method(:new_original, :new)
    PropertyTranslator.singleton_class.define_method(:new) do |property|
      translator = Object.new
      translator.define_singleton_method(:translate!) do
        raise RubyLLM::UnauthorizedError.new(nil, "Bad API key")
      end
      translator
    end

    begin
      freeze_time do
        PropertyTranslationJob.perform_now(@property.id)
        @property.reload
        assert @property.translations_status["_error"].present?
        assert_equal "RubyLLM::UnauthorizedError", @property.translations_status["_error"]["class"]
        assert_match(/Bad API key/, @property.translations_status["_error"]["message"])
        assert_equal Time.current.iso8601, @property.translations_status["_error"]["failed_at"]
      end
    ensure
      PropertyTranslator.singleton_class.alias_method(:new, :new_original)
      PropertyTranslator.singleton_class.remove_method(:new_original)
    end
  end
end
