require "test_helper"
require "rake"

class BrochuresBackfillTaskTest < ActiveJob::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  teardown do
    Rake::Task["brochures:backfill"].reenable
  end

  def build_property(reference, published: true)
    Property.create!(
      reference: reference,
      title: { "fr" => reference },
      description: { "fr" => "d" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_000_000,
      published: published
    )
  end

  test "task enqueues a job for every property" do
    p1 = build_property("BF-1")
    p2 = build_property("BF-2")
    p3 = build_property("BF-3", published: false)

    # Clear jobs enqueued by after_commit during creation.
    clear_enqueued_jobs

    Rake::Task["brochures:backfill"].invoke

    enqueued_ids = enqueued_jobs
      .select { _1[:job] == PropertyBrochureGenerationJob }
      .map { _1[:args].first }

    assert_equal [ p1.id, p2.id, p3.id ].sort, enqueued_ids.sort
  end

  test "task skips properties that already have brochures attached" do
    p1 = build_property("BF-SKIP-1")
    p2 = build_property("BF-SKIP-2")
    p1.brochures.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "x.pdf",
      content_type: "application/pdf",
      metadata: { locale: "fr", include_logo: true }
    )
    clear_enqueued_jobs

    Rake::Task["brochures:backfill"].invoke

    enqueued_ids = enqueued_jobs
      .select { _1[:job] == PropertyBrochureGenerationJob }
      .map { _1[:args].first }

    assert_equal [ p2.id ], enqueued_ids
  end

  test "FORCE=1 regenerates even when brochures already attached" do
    p1 = build_property("BF-FORCE")
    p1.brochures.attach(
      io: StringIO.new("%PDF-1.4"),
      filename: "x.pdf",
      content_type: "application/pdf",
      metadata: { locale: "fr", include_logo: true }
    )
    clear_enqueued_jobs

    ENV["FORCE"] = "1"
    Rake::Task["brochures:backfill"].invoke

    enqueued_ids = enqueued_jobs
      .select { _1[:job] == PropertyBrochureGenerationJob }
      .map { _1[:args].first }

    assert_includes enqueued_ids, p1.id
  ensure
    ENV.delete("FORCE")
  end
end
