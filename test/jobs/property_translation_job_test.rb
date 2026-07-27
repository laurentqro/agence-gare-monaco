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
    fake_new = ->(property) {
      received = property
      Object.new.tap { |o| o.define_singleton_method(:translate!) { } }
    }
    SingletonStub.with(PropertyTranslator, :new, fake_new) do
      PropertyTranslationJob.perform_now(@property.id)
    end
    assert_equal @property.id, received.id
  end

  test "records a failure when retries are exhausted, not just on discard" do
    # retry_on without a block re-raises after the last attempt, recording
    # nothing. The retries continue either way (the marker is not a gate), but
    # without it the failure is invisible: no admin banner, nothing for
    # Property.translation_failed or translations:retry_failed to find.
    fake_new = ->(_property) {
      Object.new.tap do |o|
        o.define_singleton_method(:translate!) { raise RubyLLM::ServerError.new(nil, "upstream down") }
      end
    }

    # retry_on counts attempts per rescued-exception group in exception_executions,
    # keyed by that group's Array#to_s. Pre-load it at the attempts limit so this
    # run is the final attempt and the handler takes its give-up branch.
    job = PropertyTranslationJob.new(@property.id)
    retry_group = [ RubyLLM::RateLimitError, RubyLLM::ServerError,
                    RubyLLM::ServiceUnavailableError, RubyLLM::OverloadedError,
                    Net::OpenTimeout, JSON::ParserError ]
    job.exception_executions = { retry_group.to_s => 5 }

    SingletonStub.with(PropertyTranslator, :new, fake_new) do
      assert_raises(RubyLLM::ServerError) { job.perform_now }
    end

    assert @property.reload.translation_error.present?,
           "exhausted retries must record a failure so the operator can see the property is stuck"
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
    raising_translator = ->(_property) {
      Object.new.tap do |t|
        t.define_singleton_method(:translate!) do
          raise RubyLLM::UnauthorizedError.new(nil, "Bad API key")
        end
      end
    }

    SingletonStub.with(PropertyTranslator, :new, raising_translator) do
      freeze_time do
        PropertyTranslationJob.perform_now(@property.id)
        @property.reload
        assert @property.translations_status["_error"].present?
        assert_equal "RubyLLM::UnauthorizedError", @property.translations_status["_error"]["class"]
        assert_match(/Bad API key/, @property.translations_status["_error"]["message"])
        assert_equal Time.current.iso8601, @property.translations_status["_error"]["failed_at"]
      end
    end
  end
end
