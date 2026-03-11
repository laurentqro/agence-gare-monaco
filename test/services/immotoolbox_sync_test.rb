require "test_helper"

class ImmotoolboxSyncTest < ActiveSupport::TestCase
  setup do
    @base_url = "https://clientapi.immotoolbox.com/api"

    # Stub all API endpoints with realistic data matching the actual API format
    stub_districts
    stub_buildings
    stub_properties
  end

  # --- Sync Districts ---

  test "sync creates new districts from API data" do
    assert_difference "District.count", 2 do
      ImmotoolboxSync.new(api_token: "test-token").sync_districts
    end

    district = District.find_by(immotoolbox_id: 1)
    assert_equal "Monte-Carlo", district.name
    assert_equal "Monaco", district.city
    assert_in_delta 43.7384, district.latitude.to_f, 0.0001
    assert_in_delta 7.4246, district.longitude.to_f, 0.0001
    assert_equal "monte-carlo", district.slug
  end

  test "sync updates existing districts" do
    District.create!(name: "Old Name", city: "Monaco", immotoolbox_id: 1)
    District.create!(name: "Fontvieille", city: "Monaco", immotoolbox_id: 2)

    assert_no_difference "District.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_districts
    end

    district = District.find_by(immotoolbox_id: 1)
    assert_equal "Monte-Carlo", district.name
  end

  test "sync does not delete districts not in API response" do
    District.create!(name: "Manual District", city: "Monaco")

    ImmotoolboxSync.new(api_token: "test-token").sync_districts

    assert District.find_by(name: "Manual District").present?
  end

  # --- Sync Buildings ---

  test "sync creates new buildings from API data" do
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)

    assert_difference "Building.count", 1 do
      ImmotoolboxSync.new(api_token: "test-token").sync_buildings
    end

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal "Le Millefiori", building.name
    assert_equal "Le Millefiori", building.name_alt
    assert_equal "1 Rue du Ténao", building.address
    assert_equal "Monaco", building.city
    assert_equal 1, building.district.immotoolbox_id
  end

  test "sync updates existing buildings" do
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    Building.create!(name: "Old Name", city: "Monaco", immotoolbox_id: 10)

    assert_no_difference "Building.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_buildings
    end

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal "Le Millefiori", building.name
  end

  test "sync links building to district by immotoolbox_id" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)

    ImmotoolboxSync.new(api_token: "test-token").sync_buildings

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal district, building.district
  end

  # --- Sync Properties ---

  test "sync creates new properties from API data" do
    setup_districts_and_buildings

    assert_difference "Property.count", 1 do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "AG-001", property.reference
    assert_equal 1_500_000, property.price
    assert_equal "EUR", property.currency
    assert_equal "sale", property.transaction_type
    assert_equal "apartment", property.property_type
    assert_equal "MC", property.country
    assert_equal "Monaco", property.city
    assert_equal 3, property.num_rooms
    assert_equal 2, property.num_bedrooms
    assert_equal 1, property.num_bathrooms
    assert_in_delta 75.5, property.living_area.to_f, 0.01
    assert_equal true, property.published
    assert property.synced_at.present?
  end

  test "sync sets multilingual title and description from inline texts" do
    setup_districts_and_buildings

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    assert_equal "Studio Monte-Carlo EN", property.title["en"]
    assert_equal "Magnifique studio", property.description["fr"]
    assert_equal "Beautiful studio", property.description["en"]
  end

  test "sync strips HTML tags from descriptions" do
    setup_districts_and_buildings

    # Reset stubs and re-stub with HTML descriptions
    WebMock.reset!
    html_property = property_data(
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "description" => "<p>Magnifique studio</p><p>au coeur de Monaco</p>", "languageCode" => "FR" },
        "en" => { "id" => 301, "title" => "Studio Monte-Carlo EN", "description" => "<p>Beautiful studio</p><br><p>in the heart of Monaco</p>", "languageCode" => "EN" }
      }
    )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [html_property].to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    refute_includes property.description["fr"], "<p>"
    refute_includes property.description["en"], "<br>"
    assert_includes property.description["fr"], "Magnifique studio"
    assert_includes property.description["en"], "Beautiful studio"
  end

  test "sync strips HTML entities from titles and descriptions" do
    setup_districts_and_buildings

    WebMock.reset!
    html_property = property_data(
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio&nbsp;Monte-Carlo", "description" => "Situé&nbsp;au c&oelig;ur de <b>Monaco</b>,&nbsp;proche du port", "languageCode" => "FR" },
        "en" => { "id" => 301, "title" => "Studio Monte-Carlo EN", "description" => "Located&nbsp;in the&nbsp;heart of Monaco", "languageCode" => "EN" }
      }
    )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [html_property].to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    refute_includes property.description["fr"], "&nbsp;"
    refute_includes property.description["fr"], "<b>"
    assert_includes property.description["fr"], "Situé au"
    assert_includes property.description["fr"], "proche du port"
    refute_includes property.description["en"], "&nbsp;"
    assert_equal "Located in the heart of Monaco", property.description["en"]
  end

  test "sync creates property images from inline images" do
    setup_districts_and_buildings

    assert_difference "PropertyImage.count", 2 do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    photo = property.property_images.find_by(immotoolbox_id: 200)
    assert_equal "https://cdn.example.com/large/img1.jpg", photo.remote_url
    assert_equal "https://cdn.example.com/thumb/img1.jpg", photo.thumb_url
    assert_equal "https://cdn.example.com/small/img1.jpg", photo.small_url
    assert_equal "https://cdn.example.com/medium/img1.jpg", photo.medium_url
    assert_equal "https://cdn.example.com/large/img1.jpg", photo.large_url
    assert_equal 1, photo.position
    assert_equal false, photo.is_plan

    plan = property.property_images.find_by(immotoolbox_id: 201)
    assert_equal true, plan.is_plan
  end

  test "sync updates existing properties" do
    setup_districts_and_buildings
    Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 1_000_000, immotoolbox_id: 100
    )

    assert_no_difference "Property.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal 1_500_000, property.price
  end

  test "sync skips manually_edited properties" do
    setup_districts_and_buildings
    Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 999_999, immotoolbox_id: 100,
      manually_edited: true
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal 999_999, property.price
  end

  test "sync unpublishes properties not in API response" do
    setup_districts_and_buildings
    stale = Property.create!(
      reference: "AG-OLD", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", published: true, immotoolbox_id: 999
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    stale.reload
    assert_equal false, stale.published
  end

  test "sync does not unpublish non-synced properties" do
    setup_districts_and_buildings
    manual = Property.create!(
      reference: "MANUAL-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", published: true, immotoolbox_id: nil
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    manual.reload
    assert_equal true, manual.published
  end

  test "sync links property to district and building" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    building = Building.create!(name: "Le Millefiori", city: "Monaco", immotoolbox_id: 10, district: district)

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal district, property.district
    assert_equal building, property.building
  end

  test "sync sets property media URLs" do
    setup_districts_and_buildings

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "https://youtube.com/watch?v=abc123", property.video_url
    assert_equal "https://my.matterport.com/show?m=xyz", property.virtual_tour_url
  end

  test "sync updates existing images by immotoolbox_id" do
    setup_districts_and_buildings
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100
    )
    existing_image = PropertyImage.create!(
      property: property, remote_url: "https://old.url/img.jpg",
      immotoolbox_id: 200, position: 99
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    existing_image.reload
    assert_equal "https://cdn.example.com/large/img1.jpg", existing_image.remote_url
    assert_equal 1, existing_image.position
  end

  test "sync removes images no longer in API response" do
    setup_districts_and_buildings
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100
    )
    orphan = PropertyImage.create!(
      property: property, remote_url: "https://old.url/orphan.jpg",
      immotoolbox_id: 999
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    assert_nil PropertyImage.find_by(id: orphan.id)
  end

  test "sync handles non-numeric num_rooms gracefully" do
    setup_districts_and_buildings

    # Override properties stub with non-numeric num_rooms
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [property_data(num_rooms: "Non défini/Aucun", num_bedrooms: "", num_bathrooms: "")].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_nil property.num_rooms
    assert_nil property.num_bedrooms
    assert_nil property.num_bathrooms
  end

  test "sync merges translations, preserving locales not in API" do
    setup_districts_and_buildings
    # Property already has translations in 4 locales; API only provides fr and en
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100,
      title: { "fr" => "Old FR", "en" => "Old EN", "it" => "Titolo italiano", "de" => "Deutscher Titel" },
      description: { "fr" => "Old FR desc", "en" => "Old EN desc", "it" => "Descrizione", "de" => "Beschreibung" }
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property.reload
    # API locales should be updated
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    assert_equal "Studio Monte-Carlo EN", property.title["en"]
    assert_equal "Magnifique studio", property.description["fr"]
    assert_equal "Beautiful studio", property.description["en"]
    # Non-API locales should be preserved
    assert_equal "Titolo italiano", property.title["it"]
    assert_equal "Deutscher Titel", property.title["de"]
    assert_equal "Descrizione", property.description["it"]
    assert_equal "Beschreibung", property.description["de"]
  end

  test "sync handles shared images across properties" do
    setup_districts_and_buildings

    # Two properties sharing the same image (e.g. building image)
    shared_image_id = 200
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [
          property_data,
          property_data.merge(
            "id" => 101, "reference" => "AG-002",
            "images" => [
              { "id" => shared_image_id, "order" => 1, "thumb" => "https://cdn.example.com/thumb/img1.jpg",
                "small" => "https://cdn.example.com/small/img1.jpg", "medium" => "https://cdn.example.com/medium/img1.jpg",
                "large" => "https://cdn.example.com/large/img1.jpg", "isPlan" => false }
            ]
          )
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_nothing_raised do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    assert_equal 2, Property.count
  end

  # --- Full sync ---

  test "sync_all runs districts, buildings, then properties in order" do
    setup_districts_and_buildings

    result = ImmotoolboxSync.new(api_token: "test-token").sync_all

    assert result[:districts].is_a?(Hash)
    assert result[:buildings].is_a?(Hash)
    assert result[:properties].is_a?(Hash)
    assert_operator District.count, :>=, 2
    assert_operator Building.count, :>=, 1
    assert_operator Property.count, :>=, 1
  end

  test "sync_all returns summary statistics" do
    result = ImmotoolboxSync.new(api_token: "test-token").sync_all

    assert_includes result[:districts].keys, :created
    assert_includes result[:districts].keys, :updated
    assert_includes result[:buildings].keys, :created
    assert_includes result[:buildings].keys, :updated
    assert_includes result[:properties].keys, :created
    assert_includes result[:properties].keys, :updated
    assert_includes result[:properties].keys, :unpublished
    assert_includes result[:properties].keys, :skipped
  end

  private

  def setup_districts_and_buildings
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    District.create!(name: "Fontvieille", city: "Monaco", immotoolbox_id: 2)
    Building.create!(name: "Le Millefiori", city: "Monaco", immotoolbox_id: 10,
                     district: District.find_by(immotoolbox_id: 1))
  end

  def stub_districts
    # Real API returns a Hash keyed by ID strings, not an Array
    stub_request(:get, "#{@base_url}/districts")
      .to_return(
        status: 200,
        body: {
          "1" => { "id" => 1, "name" => "Monte-Carlo", "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" }, "lat" => "43.7384", "lng" => "7.4246" },
          "2" => { "id" => 2, "name" => "Fontvieille", "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" }, "lat" => "43.7272", "lng" => "7.4145" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_buildings
    # Real API returns an Array; city is an object, name_alt uses underscore
    stub_request(:get, "#{@base_url}/buildings")
      .to_return(
        status: 200,
        body: [
          {
            "id" => 10, "name" => "Le Millefiori", "name_alt" => "Le Millefiori",
            "address" => "1 Rue du Ténao",
            "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" },
            "district" => { "id" => 1, "name" => "Monte-Carlo" }
          }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def property_data(overrides = {})
    {
      "id" => 100,
      "reference" => "AG-001",
      "price" => 1_500_000,
      "currency" => "EUR",
      "servicecharges" => 500,
      "serviceschargesIncluded" => false,
      "type_transaction_code" => "sale",
      "type_property" => "Apartment",
      "type_property_id" => 1,
      "subtype_property" => "Studio",
      "subtype_property_id" => 1,
      "country" => { "id" => 1, "code" => "MC", "name" => "Monaco" },
      "country_code" => "MC",
      "city" => { "id" => 4, "name" => "Monaco" },
      "city_name" => "Monaco",
      "district" => { "id" => 1, "name" => "Monte-Carlo" },
      "building" => "Le Millefiori",
      "building_id" => 10,
      "address" => "1 Rue du Ténao",
      "lat" => "43.7384",
      "lng" => "7.4246",
      "floor" => "5",
      "num_rooms" => overrides.fetch(:num_rooms, "3"),
      "num_bedrooms" => overrides.fetch(:num_bedrooms, "2"),
      "num_bathrooms" => overrides.fetch(:num_bathrooms, "1"),
      "num_parkings" => "1",
      "num_cellars" => "0",
      "living_area" => 75.5,
      "total_area" => 85.0,
      "terrace_area" => 10.0,
      "land_area" => nil,
      "garden_area" => nil,
      "furnished" => false,
      "status" => "published",
      "featured" => true,
      "exclusivity" => false,
      "sharedExclusivity" => false,
      "urlVideo" => "https://youtube.com/watch?v=abc123",
      "urlVirtual" => "https://my.matterport.com/show?m=xyz",
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "description" => "Magnifique studio", "languageCode" => "FR" },
        "en" => { "id" => 301, "title" => "Studio Monte-Carlo EN", "description" => "Beautiful studio", "languageCode" => "EN" }
      },
      "images" => [
        {
          "id" => 200,
          "order" => 1,
          "thumb" => "https://cdn.example.com/thumb/img1.jpg",
          "small" => "https://cdn.example.com/small/img1.jpg",
          "medium" => "https://cdn.example.com/medium/img1.jpg",
          "large" => "https://cdn.example.com/large/img1.jpg",
          "isPlan" => false
        },
        {
          "id" => 201,
          "order" => 2,
          "thumb" => "https://cdn.example.com/thumb/plan1.jpg",
          "small" => "https://cdn.example.com/small/plan1.jpg",
          "medium" => "https://cdn.example.com/medium/plan1.jpg",
          "large" => "https://cdn.example.com/large/plan1.jpg",
          "isPlan" => true
        }
      ]
    }.merge(overrides)
  end

  def stub_properties
    # Page 1: one property with inline texts and images
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [property_data].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Page 2: empty (signals end of pagination)
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
