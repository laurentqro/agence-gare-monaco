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

  test "is enqueued on default queue" do
    assert_equal "default", ImmotoolboxSyncJob.new.queue_name
  end

  test "can be enqueued" do
    assert_enqueued_with(job: ImmotoolboxSyncJob) do
      ImmotoolboxSyncJob.perform_later
    end
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
