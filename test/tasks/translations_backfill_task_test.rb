require "test_helper"
require "rake"

class TranslationsBackfillTaskTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["translations:backfill"].reenable
  end

  test "enqueues a job only for properties with no translation_source_hash" do
    missing = create_property(reference: "MC-BF-1", translation_source_hash: nil)
    done = create_property(reference: "MC-BF-2", translation_source_hash: "already-hashed")

    assert_enqueued_jobs 1, only: PropertyTranslationJob do
      Rake::Task["translations:backfill"].invoke
    end

    enqueued_ids = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }.map { |j| j[:args].first }
    assert_includes enqueued_ids, missing.id
    refute_includes enqueued_ids, done.id
  end

  test "staggers enqueues so workers do not fan out into the Anthropic API at once" do
    3.times { |i| create_property(reference: "MC-BF-S#{i}", translation_source_hash: nil) }

    Rake::Task["translations:backfill"].invoke

    jobs = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }
    scheduled = jobs.map { |j| j["scheduled_at"] }.compact
    assert_equal jobs.size, scheduled.size, "every backfill job should have a scheduled_at"
    # Two different wait offsets means at least two distinct scheduled timestamps.
    assert scheduled.uniq.size >= 2, "expected staggered scheduled_at values, got #{scheduled.inspect}"
  end

  private

  def create_property(overrides)
    defaults = {
      reference: "MC-BF-DEFAULT",
      title: { "fr" => "Titre" }, description: { "fr" => "Description" },
      transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco"
    }
    attrs = defaults.merge(overrides)
    hash = attrs.delete(:translation_source_hash)
    p = Property.create!(attrs)
    p.update_columns(translation_source_hash: hash) unless hash.nil?
    p
  end
end
