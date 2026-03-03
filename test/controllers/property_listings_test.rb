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
    # Should not include sale property cards (Studio is a filter label too, so check cards only)
    assert_select "[data-testid='property-card']", count: 1
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
    # Should not include Monaco property cards (Studio is a filter label too, so check cards only)
    assert_select "[data-testid='property-card']", count: 1
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
    assert_select "[data-testid='multiselect-type']"
  end

  test "listing page displays district filter for Monaco" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='multiselect-district']"
  end

  test "district filter not shown for France listings" do
    get "/en/sales/france"
    assert_response :success
    assert_select "[data-testid='multiselect-district']", count: 0
  end

  test "district filter not shown for all-sales listings" do
    get "/en/sales"
    assert_response :success
    assert_select "[data-testid='multiselect-district']", count: 0
  end

  # === Compound type filter: room-count-based filtering ===

  test "filtering by studio returns only 1-room apartments" do
    get "/en/sales/monaco?type[]=studio"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "filtering by 3 rooms returns only 3-room apartments" do
    get "/en/sales/monaco?type[]=3+rooms"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Fontvieille/
  end

  test "filtering by 5+ rooms returns apartments with more than 5 rooms" do
    Property.create!(
      reference: "MC-BIG",
      title: { "en" => "Big Apartment" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      num_rooms: 7,
      price: 10_000_000,
      published: true
    )
    get "/en/sales/monaco?type[]=5%2B+rooms"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Big Apartment/
  end

  test "filtering by penthouse returns only penthouse properties" do
    Property.create!(
      reference: "MC-PH",
      title: { "en" => "Luxury Penthouse" },
      transaction_type: "sale",
      property_type: "penthouse",
      country: "MC",
      city: "Monaco",
      price: 15_000_000,
      published: true
    )
    get "/en/sales/monaco?type[]=penthouse"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Penthouse/
  end

  test "filtering by office returns only office properties" do
    Property.create!(
      reference: "MC-OFFICE",
      title: { "en" => "Nice Office" },
      transaction_type: "sale",
      property_type: "office",
      country: "MC",
      city: "Monaco",
      price: 500_000,
      published: true
    )
    get "/en/sales/monaco?type[]=office"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Office/
  end

  test "filtering by single type excludes non-matching" do
    get "/en/sales/monaco?type[]=penthouse"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 0
  end

  # === Single-value district filtering ===

  test "filtering by single district via query param shows only properties in that district" do
    get "/en/sales/monaco?district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "district filter remains visible when filtering by district via query param" do
    get "/en/sales/monaco?district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='multiselect-district']"
  end

  # === Multi-select filtering ===

  test "filtering by multiple type filters returns matching properties" do
    get "/en/sales/monaco?type[]=studio&type[]=3+rooms"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 2
  end

  test "filtering by multiple districts returns properties from all selected districts" do
    get "/en/sales/monaco?district[]=carre-dor&district[]=fontvieille"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 2
    assert_select "[data-testid='property-card']", text: /Studio/
    assert_select "[data-testid='property-card']", text: /Fontvieille/
  end

  test "multi-district filter silently ignores invalid district slugs" do
    get "/en/sales/monaco?district[]=carre-dor&district[]=nonexistent"
    assert_response :success
    # Should still show the valid district's properties
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "filtering by type and district works together" do
    get "/en/sales/monaco?type[]=studio&district[]=carre-dor&district[]=fontvieille"
    assert_response :success
    # Only the studio in Carré d'Or matches type AND is in one of the districts
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
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

  # === Filter chips (multi-select, grouped) ===

  test "no filter chips shown when no filters are active" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "[data-testid='active-filters']", count: 0
  end

  test "type chip group appears with label and value when one type selected" do
    get "/en/sales/monaco?type[]=studio"
    assert_response :success
    assert_select "[data-testid='active-filters']"
    assert_select "[data-testid='filter-chip-group']", count: 1
    assert_select "[data-testid='filter-chip-group']", text: /Type/i
    assert_select "[data-testid='filter-chip']", count: 1
    assert_select "[data-testid='filter-chip']", text: /Studio/
  end

  test "type chip label is translated to current locale" do
    get "/ventes/monaco?type[]=studio"
    assert_response :success
    assert_select "[data-testid='filter-chip']", text: /Studio/
  end

  # === Localized filter params ===

  test "French locale uses localized filter param names in URL" do
    get "/ventes/monaco?quartier[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "French locale uses localized type param values" do
    # FR type_filters.studio = "Studio" -> lowercase "studio"
    get "/ventes/monaco?type[]=studio"
    assert_response :success
    assert_select "[data-testid='property-card']", { minimum: 1 }
  end

  test "French locale uses room-count type filter" do
    # FR type_filters.3-pieces = "3 Pièces" -> lowercase "3 pièces"
    get "/ventes/monaco?type[]=3+pi%C3%A8ces"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Fontvieille/
  end

  test "French locale checkbox values use translated type filter labels" do
    get "/ventes/monaco"
    assert_response :success
    assert_select "input[type='checkbox'][name='type[]'][value='studio']"
    assert_select "input[type='checkbox'][name='type[]'][value='penthouse']"
  end

  test "French locale checkbox names use localized param names" do
    get "/ventes/monaco"
    assert_response :success
    assert_select "input[type='checkbox'][name='type[]']", { minimum: 1 }
    assert_select "input[type='checkbox'][name='quartier[]']", { minimum: 1 }
  end

  test "Italian locale uses localized filter param names" do
    get "/it/vendite/monaco?quartiere[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='property-card']", count: 1
    assert_select "[data-testid='property-card']", text: /Studio/
  end

  test "Italian locale uses localized type param values" do
    # IT type_filters.studio = "Monolocale" -> lowercase "monolocale"
    get "/it/vendite/monaco?tipo[]=monolocale"
    assert_response :success
    assert_select "[data-testid='property-card']", { minimum: 1 }
  end

  test "Italian locale checkbox names use localized param names" do
    get "/it/vendite/monaco"
    assert_response :success
    assert_select "input[type='checkbox'][name='tipo[]']", { minimum: 1 }
    assert_select "input[type='checkbox'][name='quartiere[]']", { minimum: 1 }
  end

  test "type chip group contains multiple chips for multiple selected types" do
    get "/en/sales/monaco?type[]=studio&type[]=3+rooms"
    assert_response :success
    assert_select "[data-testid='filter-chip-group']", count: 1
    assert_select "[data-testid='filter-chip']", count: 2
    assert_select "[data-testid='filter-chip']", text: /studio/i
    assert_select "[data-testid='filter-chip']", text: /3 rooms/i
  end

  test "district chip group appears with label and value when one district selected" do
    get "/en/sales/monaco?district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='active-filters']"
    assert_select "[data-testid='filter-chip-group']", count: 1
    assert_select "[data-testid='filter-chip']", count: 1
    assert_select "[data-testid='filter-chip']", text: /Carré d'Or/i
  end

  test "district chip group contains multiple chips for multiple selected districts" do
    get "/en/sales/monaco?district[]=carre-dor&district[]=fontvieille"
    assert_response :success
    assert_select "[data-testid='filter-chip-group']", count: 1
    assert_select "[data-testid='filter-chip']", count: 2
  end

  test "two chip groups appear when both type and district filters are applied" do
    get "/en/sales/monaco?type[]=studio&district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='active-filters']"
    assert_select "[data-testid='filter-chip-group']", count: 2
    assert_select "[data-testid='filter-chip']", count: 2
  end

  test "chip removal link removes only that value from the array" do
    get "/en/sales/monaco?type[]=studio&district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='filter-chip'] a" do |links|
      type_remove_link = links.find { |l| !l["href"].include?("type") && l["href"].include?("district") }
      assert type_remove_link, "Expected a remove link that keeps district but removes type"

      district_remove_link = links.find { |l| !l["href"].include?("district") && l["href"].include?("type") }
      assert district_remove_link, "Expected a remove link that keeps type but removes district"
    end
  end

  test "removing one value from multi-select keeps the other values" do
    get "/en/sales/monaco?type[]=studio&type[]=3+rooms"
    assert_response :success
    assert_select "[data-testid='filter-chip'] a" do |links|
      keeps_3rooms = links.find { |l| l["href"].include?("type") && !l["href"].include?("studio") }
      assert keeps_3rooms, "Expected a remove link that keeps 3 rooms but removes studio"
      keeps_studio = links.find { |l| l["href"].include?("studio") && !l["href"].include?("3") }
      assert keeps_studio, "Expected a remove link that keeps studio but removes 3 rooms"
    end
  end

  test "clear all link removes all filters" do
    get "/en/sales/monaco?type[]=studio&district[]=carre-dor"
    assert_response :success
    assert_select "[data-testid='active-filters'] a", text: /Clear all/i do |links|
      clear_link = links.first
      refute_match(/type/, clear_link["href"])
      refute_match(/district/, clear_link["href"])
    end
  end

  # === Checkbox dropdowns ===

  test "type filter uses checkboxes instead of select" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "select[name='type']", count: 0
    assert_select "input[type='checkbox'][name='type[]']", { minimum: 1 }
  end

  test "district filter uses checkboxes instead of select" do
    get "/en/sales/monaco"
    assert_response :success
    assert_select "select[name='district']", count: 0
    assert_select "input[type='checkbox'][name='district[]']", { minimum: 1 }
  end

  test "type checkboxes are checked when values are selected" do
    get "/en/sales/monaco?type[]=studio"
    assert_response :success
    assert_select "input[type='checkbox'][name='type[]'][value='studio'][checked]"
  end

  test "district checkboxes are checked when values are selected" do
    get "/en/sales/monaco?district[]=carre-dor"
    assert_response :success
    assert_select "input[type='checkbox'][name='district[]'][value='carre-dor'][checked]"
  end

  # === Type filter dropdown groups ===

  test "type filter dropdown has divider-separated groups" do
    get "/en/sales/monaco"
    assert_response :success
    # Should have groups separated by dividers
    assert_select "[data-testid='multiselect-type'] .border-t", { minimum: 1 }
  end

  # === NOUVEAU badge for recent properties ===

  test "recently created properties show NOUVEAU badge" do
    get "/en/sales/monaco"
    assert_response :success
    # Properties created within last 30 days should have a NEW badge
    assert_select "[data-testid='new-badge']", { minimum: 1 }
  end
end
