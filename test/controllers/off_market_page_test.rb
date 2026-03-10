require "test_helper"

class OffMarketPageTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "Monte Carlo", city: "Monaco", slug: "monte-carlo")

    @off_market_sale = Property.create!(
      reference: "OM-001",
      title: { "en" => "Off-market Sale", "fr" => "Vente Hors Marché" },
      description: { "en" => "A secret sale", "fr" => "Une vente secrète" },
      price: 5_000_000,
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      off_market: true
    )

    @off_market_rental = Property.create!(
      reference: "OM-002",
      title: { "en" => "Off-market Rental", "fr" => "Location Hors Marché" },
      description: { "en" => "A secret rental", "fr" => "Une location secrète" },
      price: 10_000,
      transaction_type: "rental",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      off_market: true
    )

    @regular_property = Property.create!(
      reference: "REG-001",
      title: { "en" => "Regular Property", "fr" => "Bien Standard" },
      description: { "en" => "Normal", "fr" => "Normal" },
      price: 1_000_000,
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true,
      off_market: false
    )

    @unpublished_off_market = Property.create!(
      reference: "OM-003",
      title: { "en" => "Unpublished Off-market", "fr" => "Hors Marché Non Publié" },
      description: { "en" => "Draft", "fr" => "Brouillon" },
      price: 3_000_000,
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: false,
      off_market: true
    )
  end

  test "GET /off-market returns 200 for FR" do
    get "/off-market"
    assert_response :success
  end

  test "GET /en/off-market returns 200 for EN" do
    get "/en/off-market"
    assert_response :success
  end

  test "shows off-market sale properties" do
    get "/off-market"
    assert_select "[data-testid='property-card']", minimum: 1
    assert_select "a[href*='#{@off_market_sale.id}']"
  end

  test "shows off-market rental properties" do
    get "/off-market"
    assert_select "a[href*='#{@off_market_rental.id}']"
  end

  test "does not show regular non-off-market properties" do
    get "/off-market"
    assert_select "a[href*='#{@regular_property.id}-']", count: 0
  end

  test "does not show unpublished off-market properties" do
    get "/off-market"
    assert_select "a[href*='#{@unpublished_off_market.id}-']", count: 0
  end

  test "shows section headers for sales and rentals" do
    get "/off-market"
    assert_select "[data-testid='offmarket-sales']"
    assert_select "[data-testid='offmarket-rentals']"
  end

  test "shows empty state when no off-market properties exist" do
    Property.where(off_market: true).destroy_all
    get "/off-market"
    assert_response :success
    assert_select "[data-testid='offmarket-empty']"
  end

  test "all 8 locales return 200" do
    I18n.available_locales.each do |locale|
      path = locale == :fr ? "/off-market" : "/#{locale}/off-market"
      get path
      assert_response :success, "Expected 200 for locale #{locale} at #{path}"
    end
  end

  test "property card without images shows agency logo placeholder" do
    get "/off-market"
    assert_select "[data-testid='property-card']" do
      assert_select "[data-testid='no-image-placeholder'] img[src*='logo']"
    end
  end

  test "navbar links to off-market page" do
    get "/"
    assert_select "nav a[href='/off-market']", minimum: 1
  end

  test "homepage hero card links to off-market page" do
    get "/"
    assert_select "[data-testid='hero-cards'] a[href='/off-market']"
  end
end
