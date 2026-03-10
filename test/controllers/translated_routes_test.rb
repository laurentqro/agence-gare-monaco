require "test_helper"

class TranslatedRoutesTest < ActionDispatch::IntegrationTest
  # === Property Listings Routes ===
  # Pattern: /{locale}/{transaction} — single page per transaction type, no country/district in URL

  # Sales (all 8 locales)
  test "FR sales listing route" do
    get "/ventes"
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
    get "/locations"
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

  # === Old country/district routes now redirect 301 to simplified routes ===
  test "FR sales monaco redirects to sales" do
    get "/ventes/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/ventes"
  end

  test "EN sales monaco redirects to sales" do
    get "/en/sales/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/en/sales"
  end

  test "FR sales france redirects to sales" do
    get "/ventes/france"
    assert_response :moved_permanently
    assert_redirected_to "/ventes"
  end

  test "EN sales france redirects to sales" do
    get "/en/sales/france"
    assert_response :moved_permanently
    assert_redirected_to "/en/sales"
  end

  test "DE sales france redirects to sales" do
    get "/de/verkauf/frankreich"
    assert_response :moved_permanently
    assert_redirected_to "/de/verkauf"
  end

  test "FR rentals monaco redirects to rentals" do
    get "/locations/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/locations"
  end

  test "EN rentals monaco redirects to rentals" do
    get "/en/rentals/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/en/rentals"
  end

  test "FR sales monaco district redirects to sales" do
    District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    get "/ventes/monaco/carre-dor"
    assert_response :moved_permanently
    assert_redirected_to "/ventes"
  end

  test "EN sales monaco district redirects to sales" do
    District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    get "/en/sales/monaco/carre-dor"
    assert_response :moved_permanently
    assert_redirected_to "/en/sales"
  end

  test "FR rentals monaco district redirects to rentals" do
    District.create!(name: "Monte-Carlo", city: "Monaco", slug: "monte-carlo")
    get "/locations/monaco/monte-carlo"
    assert_response :moved_permanently
    assert_redirected_to "/locations"
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
    get "/biens/#{property.id}-studio-carre-d-or"
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
  test "FR articles listing route" do
    get "/articles"
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

  test "FR articles by category route" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    get "/articles/actualites"
    assert_response :success
  end

  test "EN articles by category route" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    get "/en/articles/actualites"
    assert_response :success
  end

  test "FR single article route" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    article = Article.create!(
      title: { "fr" => "Mon article" },
      body: { "fr" => "Contenu" },
      slug: "mon-article",
      category: category,
      published: true,
      published_at: Time.current
    )
    get "/articles/mon-article"
    assert_response :success
  end

  # === Contact Route ===
  test "FR contact route" do
    get "/contact"
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
    get "/confidentialite"
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
    get "/ventes"
    assert_response :success
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
    get "/fr/sales"
    assert_response :moved_permanently
  end

  test "nonexistent route segment returns 404" do
    get "/en/foobar"
    assert_response :not_found
  end

  # === All 8 locales work for each route type ===
  test "all 8 locales have working sales routes" do
    get "/ventes"
    assert_response :success, "Expected 200 for /ventes (fr) but got #{response.status}"

    routes = { en: "sales", it: "vendite", de: "verkauf",
               sv: "forsaljning", no: "salg", da: "salg", fi: "myynti" }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working rentals routes" do
    get "/locations"
    assert_response :success, "Expected 200 for /locations (fr) but got #{response.status}"

    routes = { en: "rentals", it: "affitti", de: "vermietung",
               sv: "uthyrning", no: "utleie", da: "udlejning", fi: "vuokraus" }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working contact routes" do
    get "/contact"
    assert_response :success, "Expected 200 for /contact (fr) but got #{response.status}"

    routes = { en: "contact", it: "contatto", de: "kontakt",
               sv: "kontakt", no: "kontakt", da: "kontakt", fi: "yhteystiedot" }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  test "all 8 locales have working privacy routes" do
    get "/confidentialite"
    assert_response :success, "Expected 200 for /confidentialite (fr) but got #{response.status}"

    routes = { en: "privacy", it: "privacy", de: "datenschutz",
               sv: "integritet", no: "personvern", da: "privatlivspolitik", fi: "tietosuoja" }
    routes.each do |locale, segment|
      get "/#{locale}/#{segment}"
      assert_response :success, "Expected 200 for /#{locale}/#{segment} but got #{response.status}"
    end
  end

  # === Query params work for filters ===
  test "query params work for property type filter on sales" do
    get "/ventes?type=studio"
    assert_response :success
  end

  test "query params work for district filter on sales" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", slug: "monte-carlo")
    get "/ventes?quartier=monte-carlo"
    assert_response :success
  end

  # === Legacy redirect for old search URLs now points to simplified sales ===
  test "legacy search redirect points to sales without country" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", slug: "monte-carlo")
    get "/fr/recherche/monte-carlo"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes"
  end
end
