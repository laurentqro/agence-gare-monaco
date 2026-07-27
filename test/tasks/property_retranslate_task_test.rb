require "test_helper"
require "rake"

class PropertyRetranslateTaskTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  teardown do
    Rake::Task["translations:retranslate"].reenable
    Rake::Task["translations:retry_failed"].reenable
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  def build_property(reference:, error: nil, hash: nil)
    property = Property.create!(
      reference: reference, transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Titre" }, description: { "fr" => "Description" }
    )
    status = error ? { "_error" => { "class" => error, "message" => "boom",
                                     "failed_at" => Time.current.iso8601 } } : {}
    property.update_columns(translation_source_hash: hash, translations_status: status)
    property
  end

  # --- translations:retranslate[ID] ---

  test "retranslate clears a recorded failure so the property is no longer stuck" do
    # enqueue_post_save_jobs! refuses to retry while an "_error" is recorded, so
    # clearing the marker is the whole point of the task: without it the enqueued
    # job would be the last one this property ever gets.
    property = build_property(reference: "RT-001", error: "RubyLLM::UnauthorizedError")

    silence_stdout { Rake::Task["translations:retranslate"].invoke(property.id.to_s) }

    property.reload
    assert_nil property.translation_error, "the recorded failure must be cleared"
    assert_nil property.translation_source_hash, "hash must be nil so the job retranslates"
  end

  test "retranslate enqueues a translation job for the property" do
    property = build_property(reference: "RT-002", error: "RubyLLM::BadRequestError")

    assert_enqueued_with(job: PropertyTranslationJob, args: [ property.id ]) do
      silence_stdout { Rake::Task["translations:retranslate"].invoke(property.id.to_s) }
    end
  end

  test "retranslate works on a healthy property with no recorded failure" do
    property = build_property(reference: "RT-003", hash: "existing-hash")

    assert_enqueued_with(job: PropertyTranslationJob, args: [ property.id ]) do
      silence_stdout { Rake::Task["translations:retranslate"].invoke(property.id.to_s) }
    end
    assert_nil property.reload.translation_source_hash
  end

  test "retranslate aborts when no id is supplied" do
    assert_raises(SystemExit) do
      silence_stdout { Rake::Task["translations:retranslate"].invoke }
    end
  end

  test "retranslate aborts when no property matches the id" do
    assert_raises(SystemExit) do
      silence_stdout { Rake::Task["translations:retranslate"].invoke("999999") }
    end
  end

  # --- translations:retry_failed ---

  test "retry_failed clears and re-enqueues every property with a recorded failure" do
    a = build_property(reference: "RF-001", error: "RubyLLM::UnauthorizedError")
    b = build_property(reference: "RF-002", error: "RubyLLM::ContextLengthExceededError")

    assert_enqueued_jobs 2, only: PropertyTranslationJob do
      silence_stdout { Rake::Task["translations:retry_failed"].invoke }
    end

    assert_nil a.reload.translation_error
    assert_nil b.reload.translation_error
  end

  test "retry_failed leaves healthy properties alone" do
    healthy = build_property(reference: "RF-003", hash: "good-hash")

    assert_no_enqueued_jobs only: PropertyTranslationJob do
      silence_stdout { Rake::Task["translations:retry_failed"].invoke }
    end

    assert_equal "good-hash", healthy.reload.translation_source_hash
  end

  test "retry_failed staggers enqueues so a bulk retry does not hammer the LLM API" do
    3.times { |i| build_property(reference: "RF-S#{i}", error: "RubyLLM::ServerError") }

    silence_stdout { Rake::Task["translations:retry_failed"].invoke }

    waits = ActiveJob::Base.queue_adapter.enqueued_jobs.map { |j| j[:at] }.compact
    assert_equal 3, waits.size, "every enqueue should carry a wait/at timestamp"
    assert_equal waits.sort, waits, "enqueues should be in increasing order"
  end

  test "retry_failed reports how many properties it retried" do
    build_property(reference: "RF-004", error: "RubyLLM::UnauthorizedError")
    build_property(reference: "RF-005", error: "RubyLLM::UnauthorizedError")

    output = silence_stdout { Rake::Task["translations:retry_failed"].invoke }
    assert_match(/2/, output)
  end
end
