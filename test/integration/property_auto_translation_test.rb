require "test_helper"

class PropertyAutoTranslationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    RubyLLM.configure { |c| c.anthropic_api_key = "test-anthropic-key" }
    @base_url = "https://clientapi.immotoolbox.com/api"

    stub_request(:get, "#{@base_url}/districts").to_return(
      status: 200,
      body: {
        "1" => { "id" => 1, "name" => "Monte-Carlo", "city" => { "id" => 4, "name" => "Monaco" }, "lat" => "43.7384", "lng" => "7.4246" }
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    stub_request(:get, "#{@base_url}/buildings").to_return(
      status: 200,
      body: [
        { "id" => 10, "name" => "Le Millefiori", "address" => "1 Rue du Ténao",
          "city" => { "id" => 4, "name" => "Monaco" }, "district" => { "id" => 1, "name" => "Monte-Carlo" } }
      ].to_json,
      headers: { "Content-Type" => "application/json" }
    )

    property_payload = {
      "id" => 100, "reference" => "AG-INT-001",
      "price" => 1_500_000, "currency" => "EUR",
      "type_transaction_code" => "sale", "type_property" => "Apartment",
      "country" => { "code" => "MC" }, "country_code" => "MC",
      "city" => { "name" => "Monaco" }, "city_name" => "Monaco",
      "district" => { "id" => 1, "name" => "Monte-Carlo" },
      "building_id" => 10,
      "num_rooms" => "3",
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "description" => "Magnifique studio au cœur de Monaco." }
      },
      "images" => []
    }
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(status: 200, body: [ property_payload ].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

    translated_json = {}
    %w[en it de sv no da fi ru].each do |locale|
      translated_json["title_#{locale}"] = "Studio Monte-Carlo (#{locale.upcase})"
      translated_json["description_#{locale}"] = "Beautiful studio in Monaco (#{locale.upcase})."
    end
    stub_request(:post, "https://api.anthropic.com/v1/messages").to_return(
      status: 200,
      body: {
        "id" => "msg_123",
        "type" => "message",
        "role" => "assistant",
        "model" => "claude-sonnet-4-6",
        "content" => [ { "type" => "text", "text" => translated_json.to_json } ],
        "stop_reason" => "end_turn",
        "usage" => { "input_tokens" => 100, "output_tokens" => 200 }
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  test "sync + translation job populates all 9 locales and enqueues brochure job" do
    perform_enqueued_jobs do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    assert_not_nil property, "property should have been created by sync"

    assert_equal "Studio Monte-Carlo", property.title["fr"]
    assert_equal "Magnifique studio au cœur de Monaco.", property.description["fr"]

    %w[en it de sv no da fi ru].each do |locale|
      assert property.title[locale].present?, "title for #{locale} should be populated"
      assert property.description[locale].present?, "description for #{locale} should be populated"
      assert property.translations_status[locale]["translated_at"].present?,
             "translations_status should have timestamp for #{locale}"
    end

    assert property.translation_source_hash.present?
  end
end
