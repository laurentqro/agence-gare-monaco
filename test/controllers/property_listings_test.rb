require "test_helper"

class PropertyListingsTest < ActionDispatch::IntegrationTest
  setup do
    @carre_dor = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @fontvieille = District.create!(name: "Fontvieille", city: "Monaco", slug: "fontvieille")

    # Published Monaco sales
    @studio_carre_dor = Property.create!(
      reference: "MC-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio dans le Carré d'Or.", "en" => "Beautiful studio in Carré d'Or." },
      transaction_type: "sale",
      property_type: "apartment",
      subtype: "studio",
      country: "MC",
      city: "Monaco",
      district: @carre_dor,
      price: 1_290_000,
      num_rooms: 1,
      num_bedrooms: 0,
      num_bathrooms: 1,
      living_area: 32,
      published: true
    )
    @studio_carre_dor.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/images/studio1.jpg",
      thumb_url: "https://cdn.immotoolbox.com/images/studio1_thumb.jpg",
      small_url: "https://cdn.immotoolbox.com/images/studio1_small.jpg",
      medium_url: "https://cdn.immotoolbox.com/images/studio1_medium.jpg",
      large_url: "https://cdn.immotoolbox.com/images/studio1_large.jpg",
      position: 0
    )

    @apt_fontvieille = Property.create!(
      reference: "MC-002",
      title: { "fr" => "3 pièces Fontvieille", "en" => "3-room Fontvieille" },
      description: { "fr" => "Bel appartement à Fontvieille.", "en" => "Nice apartment in Fontvieille." },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @fontvieille,
      price: 3_500_000,
      num_rooms: 3,
      num_bedrooms: 2,
      num_bathrooms: 1,
      living_area: 85,
      published: true
    )

    # Published Monaco rental
    @rental_mc = Property.create!(
      reference: "MC-003",
      title: { "fr" => "2 pièces Monte-Carlo", "en" => "2-room Monte-Carlo" },
      transaction_type: "rental",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 5_500,
      num_rooms: 2,
      num_bedrooms: 1,
      living_area: 55,
      published: true
    )

    # Published France sale
    @france_property = Property.create!(
      reference: "FR-001",
      title: { "fr" => "Villa Beausoleil", "en" => "Villa Beausoleil" },
      transaction_type: "sale",
      property_type: "villa",
      country: "FR",
      city: "Beausoleil",
      price: 890_000,
      num_rooms: 4,
      num_bedrooms: 3,
      living_area: 120,
      published: true
    )

    # Unpublished property (should not appear)
    @unpublished = Property.create!(
      reference: "MC-DRAFT",
      title: { "fr" => "Brouillon" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: false
    )

    # Off-market property (should not appear in public listings)
    @off_market = Property.create!(
      reference: "MC-OFF",
      title: { "fr" => "Off market" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true,
      off_market: true
    )
  end

  # === Filtering by transaction type ===

  test "sales page shows only sale properties" do
    get "/en/sales"
    assert_response :success
    assert_select "[data-testid='property-card']", { minimum: 1 }
    # Should include sale properties
    assert_select "[data-testid='property-card']", text: /Studio/
    # Should not include rentals
    assert_no_match "2-room Monte-Carlo", response.body
  end

  test "rentals page shows only rental properties" do
    get "/en/rentals"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Monte-Carlo/
    # Should not include sales
    assert_no_match "Studio", response.body
  end

  # === Filtering by country ===

  test "sales monaco page shows only Monaco sale properties" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Studio/
    # Should not include France properties
    assert_no_match "Villa Beausoleil", response.body
  end

  test "sales france page shows only France sale properties" do
    get "/en/sales/france"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Villa Beausoleil/
    # Should not include Monaco properties
    assert_no_match "Studio", response.body
  end

  # === Filtering by district ===

  test "sales monaco district page shows only properties in that district" do
    get "/en/sales/monaco/carre-dor"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Studio/
    assert_no_match "Fontvieille", response.body
  end

  # === Unpublished and off-market properties are hidden ===

  test "unpublished properties do not appear in listings" do
    get "/en/sales"
    assert_response :success
    assert_no_match "Brouillon", response.body
  end

  test "off-market properties do not appear in public listings" do
    get "/en/sales"
    assert_response :success
    assert_no_match "Off market", response.body
  end

  # === Property card content ===

  test "property card displays title in current locale" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "property card displays title in French locale" do
    get "/ventes/monaco"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "property card displays price with European formatting" do
    get "/en/sales/monaco"
    assert_response :success
    # 1290000 should display as 1.290.000 €
    assert_match(/1\.290\.000/, response.body)
  end

  test "property card displays property image" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='property-card'] img[src*='immotoolbox']"
  end

  test "property card displays room count" do
    get "/en/sales/monaco"
    assert_response :success
    # The card should show room info
    assert_select "[data-testid='property-card']", text: /32/  # living area
  end

  test "property card links to property detail page" do
    get "/en/sales/monaco"
    assert_response :success
    props_segment = I18n.t("routes.properties", locale: :en)
    assert_select "[data-testid='property-card'] a[href*='/en/#{props_segment}/#{@studio_carre_dor.id}']"
  end

  # === Filter UI ===

  test "listing page displays property type filter" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='filters']"
    assert_select "select[name='type']"
  end

  test "listing page displays district filter for Monaco" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "select[name='district']"
  end

  test "district filter not shown for France listings" do
    get "/en/sales/france"
    assert_response :success
    assert_select "select[name='district']", count: 0
  end

  test "district filter not shown for all-sales listings" do
    get "/en/sales"
    assert_response :success
    assert_select "select[name='district']", count: 0
  end

  test "filtering by district via query param shows only properties in that district" do
    get "/en/sales/monaco?district=carre-dor"
    assert_response :success
    assert_select "[data-testid='property-card']", text: /Studio/
    assert_no_match "Fontvieille", response.body
  end

  test "filtering by invalid district via query param returns 404" do
    get "/en/sales/monaco?district=nonexistent"
    assert_response :not_found
  end

  test "filtering by district and type via query params works together" do
    Property.create!(
      reference: "MC-004",
      title: { "en" => "Carré d'Or Villa" },
      transaction_type: "sale",
      property_type: "villa",
      country: "MC",
      city: "Monaco",
      district: @carre_dor,
      price: 5_000_000,
      published: true
    )
    get "/en/sales/monaco?district=carre-dor&type=villa"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Villa/
  end

  test "filtering by property type via query param" do
    get "/en/sales/monaco?type=apartment"
    assert_response :success
    assert_select "[data-testid='property-card']", { minimum: 1 }
  end

  test "filtering by property type excludes non-matching" do
    get "/en/sales/monaco?type=villa"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 0
  end

  # === Page heading ===

  test "sales page shows translated heading" do
    get "/en/sales"
    assert_response :success
    assert_select "h1", text: /Sales/i
  end

  test "sales monaco page shows translated heading with country" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "h1", text: /Monaco/i
  end

  test "sales monaco district page shows heading with district name" do
    get "/en/sales/monaco/carre-dor"
    assert_response :success
    assert_select "h1", text: /Carré d'Or/i
  end

  test "rentals page shows translated heading" do
    get "/en/rentals"
    assert_response :success
    assert_select "h1", text: /Rentals/i
  end

  test "france sales page shows translated heading" do
    get "/en/sales/france"
    assert_response :success
    assert_select "h1", text: /France/i
  end

  # === Property count ===

  test "listing page shows property count" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='property-count']"
  end

  # === Empty state ===

  test "listing page shows message when no properties match" do
    get "/en/rentals/monaco/carre-dor"
    # No rentals in Carré d'Or district
    assert_response :success
    assert_select "[data-testid='empty-state']"
  end

  # === Locale rendering ===

  test "listing renders correctly for all 8 locales" do
    locales_with_sales = {
      en: "sales", it: "vendite", de: "verkauf",
      sv: "forsaljning", no: "salg", da: "salg", fi: "myynti"
    }
    # French has no locale prefix
    get "/ventes/monaco"
    assert_response :success, "Failed for locale fr"
    assert_select "h1", { minimum: 1 }, "Missing h1 for locale fr"
    assert_select "[data-testid='property-card']", { minimum: 1 }, "Missing property cards for locale fr"

    locales_with_sales.each do |locale, segment|
      get "/#{locale}/#{segment}/monaco"
      assert_response :success, "Failed for locale #{locale}"
      assert_select "h1", { minimum: 1 }, "Missing h1 for locale #{locale}"
      assert_select "[data-testid='property-card']", { minimum: 1 }, "Missing property cards for locale #{locale}"
    end
  end

  # === NOUVEAU badge for recent properties ===

  test "recently created properties show NOUVEAU badge" do
    get "/en/sales/monaco"
    assert_response :success
    # Properties created within last 30 days should have a NEW badge
    assert_select "[data-testid='new-badge']", { minimum: 1 }
  end
end
