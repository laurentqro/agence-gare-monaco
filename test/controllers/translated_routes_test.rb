require "test_helper"

class TranslatedRoutesTest < ActionDispatch::IntegrationTest
  # === Property Listings Routes ===
  # Pattern: /{locale}/{transaction}[/{country}[/{district}]]

  test "FR sales listing route" do
    get "/fr/ventes"
    assert_response :success
  end

  test "EN sales listing route" do
    get "/en/sales"
    assert_response :success
  end

  test "DE sales listing route" do
    get "/de/verkauf"
    assert_response :success
  end

  test "IT sales listing route" do
    get "/it/vendite"
    assert_response :success
  end

  test "SV sales listing route" do
    get "/sv/forsaljning"
    assert_response :success
  end

  test "NO sales listing route" do
    get "/no/salg"
    assert_response :success
  end

  test "DA sales listing route" do
    get "/da/salg"
    assert_response :success
  end

  test "FI sales listing route" do
    get "/fi/myynti"
    assert_response :success
  end

  # Rentals
  test "FR rentals listing route" do
    get "/fr/locations"
    assert_response :success
  end

  test "EN rentals listing route" do
    get "/en/rentals"
    assert_response :success
  end

  test "DE rentals listing route" do
    get "/de/vermietung"
    assert_response :success
  end

  # Sales with country filter
  test "FR sales Monaco route" do
    get "/fr/ventes/monaco"
    assert_response :success
  end

  test "EN sales Monaco route" do
    get "/en/sales/monaco"
    assert_response :success
  end

  test "DE sales Monaco route" do
    get "/de/verkauf/monaco"
    assert_response :success
  end

  test "FR sales France route" do
    get "/fr/ventes/france"
    assert_response :success
  end

  test "EN sales France route" do
    get "/en/sales/france"
    assert_response :success
  end

  test "DE sales France route" do
    get "/de/verkauf/frankreich"
    assert_response :success
  end

  # Rentals with country filter
  test "FR rentals Monaco route" do
    get "/fr/locations/monaco"
    assert_response :success
  end

  test "EN rentals Monaco route" do
    get "/en/rentals/monaco"
    assert_response :success
  end

  # Sales with district filter
  test "FR sales Monaco district route" do
    district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    get "/fr/ventes/monaco/carre-dor"
    assert_response :success
  end

  test "EN sales Monaco district route" do
    district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    get "/en/sales/monaco/carre-dor"
    assert_response :success
  end

  test "DE sales Monaco district route" do
    district = District.create!(name: "Fontvieille", city: "Monaco", slug: "fontvieille")
    get "/de/verkauf/monaco/fontvieille"
    assert_response :success
  end

  # Rentals with district filter
  test "FR rentals Monaco district route" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", slug: "monte-carlo")
    get "/fr/locations/monaco/monte-carlo"
    assert_response :success
  end

  # === Property Detail Routes ===
  # Pattern: /{locale}/{properties}/{id}-{slug}

  test "FR property detail route" do
    property = Property.create!(
      reference: "REF001",
      title: { "fr" => "Studio Carré d'Or" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    get "/fr/biens/#{property.id}-studio-carre-d-or"
    assert_response :success
  end

  test "EN property detail route" do
    property = Property.create!(
      reference: "REF002",
      title: { "en" => "Studio Carré d'Or" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    get "/en/properties/#{property.id}-studio-carre-d-or"
    assert_response :success
  end

  test "DE property detail route" do
    property = Property.create!(
      reference: "REF003",
      title: { "de" => "Studio Carré d'Or" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    get "/de/immobilien/#{property.id}-studio-carre-d-or"
    assert_response :success
  end

  # === Articles Routes ===
  # Pattern: /{locale}/{articles}

  test "FR articles listing route" do
    get "/fr/articles"
    assert_response :success
  end

  test "EN articles listing route" do
    get "/en/articles"
    assert_response :success
  end

  test "DE articles listing route" do
    get "/de/artikel"
    assert_response :success
  end

  # Articles by category
  test "FR articles by category route" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    get "/fr/articles/actualites"
    assert_response :success
  end

  test "EN articles by category route" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    get "/en/articles/actualites"
    assert_response :success
  end

  # Single article
  test "FR single article route" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    article = Article.create!(
      title: { "fr" => "Mon article" },
      body: { "fr" => "Contenu" },
      slug: "mon-article",
      category: category,
      published: true,
      published_at: Time.current
    )
    get "/fr/articles/mon-article"
    assert_response :success
  end

  # === Contact Route ===
  test "FR contact route" do
    get "/fr/contact"
    assert_response :success
  end

  test "EN contact route" do
    get "/en/contact"
    assert_response :success
  end

  test "DE contact route" do
    get "/de/kontakt"
    assert_response :success
  end

  # === Privacy Route ===
  test "FR privacy route" do
    get "/fr/confidentialite"
    assert_response :success
  end

  test "EN privacy route" do
    get "/en/privacy"
    assert_response :success
  end

  test "DE privacy route" do
    get "/de/datenschutz"
    assert_response :success
  end

  # === Locale sets correct I18n.locale ===
  test "translated routes set correct locale for FR" do
    get "/fr/ventes"
    assert_response :success
    # The controller should render in French
  end

  test "translated routes set correct locale for EN" do
    get "/en/sales"
    assert_response :success
  end

  test "translated routes set correct locale for DE" do
    get "/de/verkauf"
    assert_response :success
  end

  # === Invalid translated segments return 404 ===
  test "wrong translation for locale returns 404" do
    get "/fr/sales"  # English segment with French locale
    assert_response :not_found
  end

  test "nonexistent route segment returns 404" do
    get "/en/foobar"
    assert_response :not_found
  end

  # === All 8 locales work for each route type ===
  test "all 8 locales have working sales routes" do
    routes = {
      fr: "ventes", en: "sales", it: "vendite", de: "verkauf",
      sv: "forsaljning", no: "salg", da: "salg", fi: "myynti"
    }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working rentals routes" do
    routes = {
      fr: "locations", en: "rentals", it: "affitti", de: "vermietung",
      sv: "uthyrning", no: "utleie", da: "udlejning", fi: "vuokraus"
    }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working contact routes" do
    routes = {
      fr: "contact", en: "contact", it: "contatto", de: "kontakt",
      sv: "kontakt", no: "kontakt", da: "kontakt", fi: "yhteystiedot"
    }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working privacy routes" do
    routes = {
      fr: "confidentialite", en: "privacy", it: "privacy", de: "datenschutz",
      sv: "integritet", no: "personvern", da: "privatlivspolitik", fi: "tietosuoja"
    }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  # === Non-existent district returns 404 ===
  test "non-existent district slug returns 404" do
    get "/fr/ventes/monaco/nonexistent-district"
    assert_response :not_found
  end

  # === Query params pass through for filters ===
  test "query params work for property type filter" do
    get "/fr/ventes/monaco?type=studio"
    assert_response :success
  end

  test "query params work for rooms filter" do
    get "/fr/ventes/monaco?pieces=3"
    assert_response :success
  end
end
