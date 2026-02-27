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

  test "scope for_rental returns rental properties" do
    Property.create!(reference: "MC-SALE", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    Property.create!(reference: "MC-RENT", transaction_type: "rental", property_type: "apartment", country: "MC", city: "Monaco")
    assert_equal 1, Property.for_rental.count
    assert_equal "MC-RENT", Property.for_rental.first.reference
  end
end
