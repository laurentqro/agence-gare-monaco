require "test_helper"

class ImmotoolboxSyncJobTest < ActiveJob::TestCase
  test "performs sync with api token from credentials" do
    stub_request(:get, "https://clientapi.immotoolbox.com/api/districts")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://clientapi.immotoolbox.com/api/buildings")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://clientapi.immotoolbox.com/api/properties?status=published&page=1")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    with_credentials(immotoolbox: { api_token: "cred-token-789" }) do
      ImmotoolboxSyncJob.perform_now
    end

    assert_requested(:get, "https://clientapi.immotoolbox.com/api/districts",
      headers: { "X-AUTH-TOKEN" => "cred-token-789" })
  end

  test "does not run sync when no api token in credentials" do
    with_credentials(immotoolbox: { api_token: nil }) do
      ImmotoolboxSyncJob.perform_now
    end

    assert_not_requested(:get, /clientapi\.immotoolbox\.com/)
  end

  test "logs sync results on success" do
    stub_request(:get, "https://clientapi.immotoolbox.com/api/districts")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://clientapi.immotoolbox.com/api/buildings")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://clientapi.immotoolbox.com/api/properties?status=published&page=1")
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })

    output = nil
    with_credentials(immotoolbox: { api_token: "test-token" }) do
      output = capture_log { ImmotoolboxSyncJob.perform_now }
    end

    assert_match(/Immotoolbox sync complete/i, output)
    assert_match(/Districts/, output)
    assert_match(/Buildings/, output)
    assert_match(/Properties/, output)
  end

  test "logs warning when no api token" do
    output = nil
    with_credentials(immotoolbox: { api_token: nil }) do
      output = capture_log { ImmotoolboxSyncJob.perform_now }
    end

    assert_match(/no.*api.*token/i, output)
  end

  test "retries on API errors" do
    rescue_classes = ImmotoolboxSyncJob.rescue_handlers.map { |h| h[0] }
    assert_includes rescue_classes, "ImmotoolboxClient::ApiError"
  end

  test "retries on network timeout errors" do
    rescue_classes = ImmotoolboxSyncJob.rescue_handlers.map { |h| h[0] }
    assert_includes rescue_classes, "Net::OpenTimeout"
  end

  test "logs every failing attempt so a fault is visible even when retries are discarded" do
    # on_conflict: :discard applies to retry_on's re-enqueues too: a retry whose
    # due time lands while the next 5-minute tick holds the semaphore is
    # destroyed, and discarded runs never burn the attempts counter, so a
    # persistent upstream fault may never exhaust into Solid Queue's failed set.
    # The error log line is the operator visibility that does not depend on it.
    stub_request(:get, "https://clientapi.immotoolbox.com/api/districts")
      .to_return(status: 500, body: "upstream down")

    output = nil
    with_credentials(immotoolbox: { api_token: "test-token" }) do
      output = capture_log { ImmotoolboxSyncJob.perform_now }
    end

    assert_match(/sync failed/i, output, "each failing attempt must produce an error log line")
    assert_match(/ApiError/, output, "the log line must name the error")
  end

  test "is enqueued on default queue" do
    assert_equal "default", ImmotoolboxSyncJob.new.queue_name
  end

  test "can be enqueued" do
    assert_enqueued_with(job: ImmotoolboxSyncJob) do
      ImmotoolboxSyncJob.perform_later
    end
  end

  test "never runs two syncs at once" do
    # The recurring schedule fires every 5 minutes, but a run has no fixed
    # duration: it pulls every page of the catalogue and each HTTP call allows a
    # 30s read timeout. A slow run must delay the next one rather than race it,
    # since two concurrent syncs write the same rows and the loser re-triggers
    # change detection, re-enqueuing brochure jobs for unchanged properties.
    assert_equal 1, ImmotoolboxSyncJob.concurrency_limit,
                 "expected the sync to be serialized (concurrency limit 1)"

    # The job takes no arguments, so every run must share one global key,
    # unlike the per-property brochure job, whose key is scoped to its argument.
    key = ImmotoolboxSyncJob.new.concurrency_key
    assert key.present?, "expected a global concurrency key for the sync"
    assert_equal key, ImmotoolboxSyncJob.new.concurrency_key,
                 "two sync runs must compute the same key so they serialize"
  end

  test "skips a scheduled sync instead of queueing it behind a running one" do
    # Every run is a full catalogue pull, so a run that fires while another is
    # in flight is redundant: the next scheduled tick supersedes it. Blocking
    # (Solid Queue's default) would stack those ticks and release them
    # back-to-back once the slow run finished, producing a burst of pointless
    # full syncs. Discarding keeps the cadence at "every 5 minutes at most".
    assert_equal "discard", ImmotoolboxSyncJob.concurrency_on_conflict.to_s,
                 "a sync that collides with a running one must be dropped, not queued"
  end

  test "concurrency lock outlasts a slow full-catalogue sync" do
    # The lock must outlive the worst-case run so it cannot expire mid-sync and
    # let a second run in. A full pull is many paginated calls at up to 30s each,
    # so the Solid Queue default of 3 minutes is not enough headroom.
    assert_operator ImmotoolboxSyncJob.concurrency_duration, :>=, 10.minutes,
                    "expected a concurrency duration well above worst-case sync time"
  end

  private

  def capture_log
    output = StringIO.new
    old_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(output)
    yield
    output.string
  ensure
    Rails.logger = old_logger
  end

  def with_credentials(hash)
    original_credentials = Rails.application.credentials
    fake_credentials = ActiveSupport::InheritableOptions.new(hash)
    Rails.application.define_singleton_method(:credentials) { fake_credentials }
    yield
  ensure
    Rails.application.define_singleton_method(:credentials) { original_credentials }
  end
end
