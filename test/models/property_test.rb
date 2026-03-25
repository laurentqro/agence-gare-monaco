require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "Monte-Carlo", city: "Monaco")
    @building = Building.create!(name: "Le Montaigne", city: "Monaco", district: @district)
  end

  test "valid property with minimal attributes" do
    property = Property.new(
      reference: "MC-001",
      title: { "fr" => "Studio Monte-Carlo", "en" => "Studio Monte-Carlo" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    assert property.valid?
  end

  test "requires reference" do
    property = Property.new(transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:reference], "can't be blank"
  end

  test "reference is unique" do
    Property.create!(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    duplicate = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference], "has already been taken"
  end

  test "requires transaction_type" do
    property = Property.new(reference: "MC-001", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:transaction_type], "can't be blank"
  end

  test "transaction_type must be sale or rental" do
    property = Property.new(reference: "MC-001", transaction_type: "lease", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:transaction_type], "is not included in the list"
  end

  test "requires property_type" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:property_type], "can't be blank"
  end

  test "requires country" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:country], "can't be blank"
  end

  test "requires city" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC")
    assert_not property.valid?
    assert_includes property.errors[:city], "can't be blank"
  end

  test "title is stored as JSON" do
    property = Property.create!(
      reference: "MC-001",
      title: { "fr" => "Studio", "en" => "Studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    property.reload
    assert_equal "Studio", property.title["fr"]
    assert_equal "Studio", property.title["en"]
  end

  test "description is stored as JSON" do
    property = Property.create!(
      reference: "MC-001",
      title: { "fr" => "Studio" },
      description: { "fr" => "Beau studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    property.reload
    assert_equal "Beau studio", property.description["fr"]
  end

  test "belongs to district optionally" do
    property = Property.new(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert property.valid?
    assert_nil property.district
  end

  test "belongs to building optionally" do
    property = Property.new(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert property.valid?
    assert_nil property.building
  end

  test "has many property_images" do
    assert_equal :has_many, Property.reflect_on_association(:property_images).macro
  end

  test "has many property_documents" do
    assert_equal :has_many, Property.reflect_on_association(:property_documents).macro
  end

  test "defaults published to false" do
    property = Property.create!(
      reference: "MC-002",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert_equal false, property.published
  end

  test "defaults off_market to false" do
    property = Property.create!(
      reference: "MC-003",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert_equal false, property.off_market
  end

  test "immotoolbox_id is unique when present" do
    Property.create!(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", immotoolbox_id: 100)
    duplicate = Property.new(reference: "MC-002", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", immotoolbox_id: 100)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:immotoolbox_id], "has already been taken"
  end

  test "stores numeric fields" do
    property = Property.create!(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      num_rooms: 3,
      num_bedrooms: 2,
      num_bathrooms: 1,
      num_parkings: 1,
      num_cellars: 0,
      living_area: 85.5,
      total_area: 120.0,
      terrace_area: 15.0,
      floor: 5
    )
    property.reload
    assert_equal 1_290_000, property.price
    assert_equal 3, property.num_rooms
    assert_equal 2, property.num_bedrooms
    assert_equal 1, property.num_bathrooms
    assert_equal 1, property.num_parkings
    assert_equal 0, property.num_cellars
    assert_in_delta 85.5, property.living_area
    assert_in_delta 120.0, property.total_area
    assert_in_delta 15.0, property.terrace_area
    assert_equal 5, property.floor
  end

  test "scope published returns only published properties" do
    Property.create!(reference: "MC-PUB", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", published: true)
    Property.create!(reference: "MC-UNP", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", published: false)
    assert_equal 1, Property.published.count
    assert_equal "MC-PUB", Property.published.first.reference
  end

  test "scope for_sale returns sale properties" do
    Property.create!(reference: "MC-SALE", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    Property.create!(reference: "MC-RENT", transaction_type: "rental", property_type: "apartment", country: "MC", city: "Monaco")
    assert_equal 1, Property.for_sale.count
    assert_equal "MC-SALE", Property.for_sale.first.reference
  end

  test "title_for skips empty string and falls back to French" do
    property = Property.new(
      reference: "MC-T1", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Studio Monaco", "it" => "" }
    )
    assert_equal "Studio Monaco", property.title_for(:it)
  end

  test "description_for skips empty string and falls back to French" do
    property = Property.new(
      reference: "MC-T2", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Studio" },
      description: { "fr" => "Beau studio", "it" => "" }
    )
    assert_equal "Beau studio", property.description_for(:it)
  end

  test "location_label returns building name and district name" do
    property = Property.new(
      reference: "MC-LOC1", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", building: @building, district: @district
    )
    assert_equal "Le Montaigne, Monte-Carlo", property.location_label
  end

  test "location_label returns district name when no building" do
    property = Property.new(
      reference: "MC-LOC2", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", district: @district
    )
    assert_equal "Monte-Carlo", property.location_label
  end

  test "location_label returns building name when no district" do
    building_no_district = Building.create!(name: "Le Panorama", city: "Monaco")
    property = Property.new(
      reference: "MC-LOC3", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", building: building_no_district
    )
    assert_equal "Le Panorama", property.location_label
  end

  test "location_label returns city when no building and no district" do
    property = Property.new(
      reference: "MC-LOC4", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco"
    )
    assert_equal "Monaco", property.location_label
  end

  test "brochure_filename with rooms district and building" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2,
      district: @district, building: @building
    )
    assert_equal "2p-monte-carlo-le-montaigne.pdf", property.brochure_filename
  end

  test "brochure_filename without building" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 3,
      district: @district
    )
    assert_equal "3p-monte-carlo.pdf", property.brochure_filename
  end

  test "brochure_filename without district or building falls back to reference" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2
    )
    assert_equal "2p-MC-001.pdf", property.brochure_filename
  end

  test "brochure_filename without rooms" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      district: @district, building: @building
    )
    assert_equal "monte-carlo-le-montaigne.pdf", property.brochure_filename
  end

  test "brochure_filename parameterizes names" do
    district = District.create!(name: "La Condamine", city: "Monaco")
    building = Building.create!(name: "Résidence Stella", city: "Monaco", district: district)
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2,
      district: district, building: building
    )
    assert_equal "2p-la-condamine-residence-stella.pdf", property.brochure_filename
  end

  test "scope for_rental returns rental properties" do
    Property.create!(reference: "MC-SALE", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    Property.create!(reference: "MC-RENT", transaction_type: "rental", property_type: "apartment", country: "MC", city: "Monaco")
    assert_equal 1, Property.for_rental.count
    assert_equal "MC-RENT", Property.for_rental.first.reference
  end
end
