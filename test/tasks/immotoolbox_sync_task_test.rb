require "test_helper"
require "rake"

class ImmotoolboxSyncTaskTest < ActiveSupport::TestCase
  setup do
    @base_url = "https://clientapi.immotoolbox.com/api"

    Rails.application.load_tasks if Rake::Task.tasks.empty?

    stub_request(:get, "#{@base_url}/districts")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/buildings")
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })
  end

  test "immotoolbox:sync task exists" do
    assert Rake::Task.task_defined?("immotoolbox:sync")
  end

  test "immotoolbox:sync task runs sync_all" do
    with_credentials(immotoolbox: { api_token: "test-token" }) do
      assert_nothing_raised do
        Rake::Task["immotoolbox:sync"].invoke
      end
    end
  ensure
    Rake::Task["immotoolbox:sync"].reenable
  end

  private

  def with_credentials(hash)
    original_credentials = Rails.application.credentials
    fake_credentials = ActiveSupport::InheritableOptions.new(hash)
    Rails.application.define_singleton_method(:credentials) { fake_credentials }
    yield
  ensure
    Rails.application.define_singleton_method(:credentials) { original_credentials }
  end
end
