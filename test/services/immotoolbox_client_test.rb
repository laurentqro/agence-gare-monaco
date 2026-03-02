require "test_helper"

class ImmotoolboxClientTest < ActiveSupport::TestCase
  setup do
    @client = ImmotoolboxClient.new(api_token: "test-token")
    @base_url = "https://clientapi.immotoolbox.com/api"
  end

  test "initializes with api_token" do
    client = ImmotoolboxClient.new(api_token: "my-token")
    assert_instance_of ImmotoolboxClient, client
  end

  test "raises error without api_token" do
    assert_raises(ArgumentError) { ImmotoolboxClient.new(api_token: nil) }
    assert_raises(ArgumentError) { ImmotoolboxClient.new(api_token: "") }
  end

  # --- Districts ---

  test "fetch_districts returns parsed district data" do
    stub_request(:get, "#{@base_url}/districts")
      .with(headers: { "X-AUTH-TOKEN" => "test-token", "Accept" => "application/json" })
      .to_return(
        status: 200,
        body: {
          "1" => { "id" => 1, "name" => "Monte-Carlo", "city" => { "id" => 4, "name" => "Monaco" }, "lat" => "43.7384", "lng" => "7.4246" },
          "2" => { "id" => 2, "name" => "Fontvieille", "city" => { "id" => 4, "name" => "Monaco" }, "lat" => "43.7272", "lng" => "7.4145" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    districts = @client.fetch_districts
    assert_equal 2, districts.size
    assert_equal "Monte-Carlo", districts["1"]["name"]
    assert_equal 1, districts["1"]["id"]
  end

  # --- Buildings ---

  test "fetch_buildings returns parsed building data" do
    stub_request(:get, "#{@base_url}/buildings")
      .with(headers: { "X-AUTH-TOKEN" => "test-token" })
      .to_return(
        status: 200,
        body: [
          { "id" => 10, "name" => "Le Millefiori", "address" => "1 Rue du Ténao", "city" => "Monaco", "district" => { "id" => 1 } }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    buildings = @client.fetch_buildings
    assert_equal 1, buildings.size
    assert_equal "Le Millefiori", buildings.first["name"]
  end

  # --- Properties ---

  test "fetch_properties returns published properties with pagination" do
    stub_request(:get, "#{@base_url}/properties")
      .with(
        headers: { "X-AUTH-TOKEN" => "test-token" },
        query: { "status" => "published", "page" => "1" }
      )
      .to_return(
        status: 200,
        body: [
          { "id" => 100, "reference" => "AG-001", "price" => 1_500_000 }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    properties = @client.fetch_properties(page: 1)
    assert_equal 1, properties.size
    assert_equal "AG-001", properties.first["reference"]
  end

  test "fetch_properties with empty page returns empty array" do
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    properties = @client.fetch_properties(page: 2)
    assert_equal [], properties
  end

  test "fetch_all_properties paginates through all pages" do
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: Array.new(20) { |i| { "id" => i + 1, "reference" => "AG-#{i + 1}" } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [{ "id" => 21, "reference" => "AG-21" }].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "3" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    properties = @client.fetch_all_properties
    assert_equal 21, properties.size
  end

  # --- Property Detail ---

  test "fetch_property returns single property with full detail" do
    stub_request(:get, "#{@base_url}/properties/100")
      .with(headers: { "X-AUTH-TOKEN" => "test-token" })
      .to_return(
        status: 200,
        body: {
          "id" => 100,
          "reference" => "AG-001",
          "price" => 1_500_000,
          "buildingDetails" => { "id" => 10, "name" => "Le Millefiori" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    property = @client.fetch_property(100)
    assert_equal "AG-001", property["reference"]
    assert_equal "Le Millefiori", property.dig("buildingDetails", "name")
  end

  # --- Images ---

  test "fetch_images returns images for a property" do
    stub_request(:get, "#{@base_url}/images")
      .with(
        headers: { "X-AUTH-TOKEN" => "test-token" },
        query: { "property" => "100" }
      )
      .to_return(
        status: 200,
        body: [
          {
            "id" => 200,
            "urls" => {
              "thumb" => "https://cdn.example.com/thumb/img1.jpg",
              "small" => "https://cdn.example.com/small/img1.jpg",
              "medium" => "https://cdn.example.com/medium/img1.jpg",
              "large" => "https://cdn.example.com/large/img1.jpg"
            },
            "isPlan" => false,
            "position" => 1
          }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    images = @client.fetch_images(property_id: 100)
    assert_equal 1, images.size
    assert_equal 200, images.first["id"]
  end

  # --- Texts ---

  test "fetch_texts returns multilingual texts for a property" do
    stub_request(:get, "#{@base_url}/texts")
      .with(
        headers: { "X-AUTH-TOKEN" => "test-token" },
        query: { "property" => "100" }
      )
      .to_return(
        status: 200,
        body: [
          { "id" => 300, "language" => "fr", "title" => "Studio Monte-Carlo", "description" => "Magnifique studio" },
          { "id" => 301, "language" => "en", "title" => "Studio Monte-Carlo", "description" => "Beautiful studio" }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    texts = @client.fetch_texts(property_id: 100)
    assert_equal 2, texts.size
    assert_equal "fr", texts.first["language"]
  end

  # --- Error handling ---

  test "raises ApiError on 401 unauthorized" do
    stub_request(:get, "#{@base_url}/districts")
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(ImmotoolboxClient::ApiError) { @client.fetch_districts }
  end

  test "raises ApiError on 500 server error" do
    stub_request(:get, "#{@base_url}/districts")
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(ImmotoolboxClient::ApiError) { @client.fetch_districts }
  end

  test "raises ApiError on network timeout" do
    stub_request(:get, "#{@base_url}/districts")
      .to_timeout

    assert_raises(ImmotoolboxClient::ApiError) { @client.fetch_districts }
  end
end
