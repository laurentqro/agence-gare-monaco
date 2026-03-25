require "test_helper"

class SeoIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @property = Property.create!(
      reference: "SEO-INT-001",
      title: { "en" => "Luxury Apartment", "fr" => "Appartement de Luxe" },
      description: { "en" => "A stunning apartment in Monaco.", "fr" => "Un magnifique appartement à Monaco." },
      price: 2_500_000,
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      off_market: false,
      num_rooms: 3,
      num_bedrooms: 2,
      num_bathrooms: 1,
      living_area: 85.0,
      latitude: 43.738,
      longitude: 7.427
    )
    @property.property_images.create!(
      remote_url: "https://cdn.example.com/apt1.jpg",
      large_url: "https://cdn.example.com/apt1_large.jpg",
      position: 1
    )
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    @article = Article.create!(
      title: { "en" => "Market Trends 2025", "fr" => "Tendances du Marché 2025" },
      body: { "en" => "The real estate market in Monaco.", "fr" => "Le marché immobilier à Monaco." },
      slug: "market-trends-2025",
      category: @category,
      published: true,
      published_at: Time.zone.parse("2025-06-01")
    )
  end

  # --- Homepage SEO ---

  test "homepage has canonical link" do
    get "/en"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en"]'
  end

  test "homepage has hreflang tags for all locales" do
    get "/"
    assert_response :success
    assert_select 'link[rel="alternate"][hreflang="fr"]'
    assert_select 'link[rel="alternate"][hreflang="en"]'
    assert_select 'link[rel="alternate"][hreflang="de"]'
    assert_select 'link[rel="alternate"][hreflang="it"]'
    assert_select 'link[rel="alternate"][hreflang="sv"]'
    assert_select 'link[rel="alternate"][hreflang="nb"]'
    assert_select 'link[rel="alternate"][hreflang="da"]'
    assert_select 'link[rel="alternate"][hreflang="fi"]'
    assert_select 'link[rel="alternate"][hreflang="x-default"]'
  end

  test "homepage has meta description" do
    get "/en"
    assert_response :success
    assert_select 'meta[name="description"]' do |elements|
      assert elements.first["content"].present?
    end
  end

  test "homepage has Open Graph tags" do
    get "/en"
    assert_response :success
    assert_select 'meta[property="og:type"][content="website"]'
    assert_select 'meta[property="og:site_name"]'
    assert_select 'meta[property="og:locale"]'
    assert_select 'meta[property="og:url"]'
    assert_select 'meta[property="og:title"]'
    assert_select 'meta[property="og:description"]'
  end

  test "homepage has Twitter Card tags" do
    get "/en"
    assert_response :success
    assert_select 'meta[name="twitter:card"][content="summary_large_image"]'
    assert_select 'meta[name="twitter:title"]'
  end

  test "homepage has JSON-LD organization schema" do
    get "/en"
    assert_response :success
    assert_select 'script[type="application/ld+json"]', minimum: 1
    scripts = css_select('script[type="application/ld+json"]')
    json_contents = scripts.map { |s| JSON.parse(s.text) }
    org = json_contents.find { |j| j["@type"] == "RealEstateAgent" }
    assert_not_nil org
    assert_equal "Agence Immobilière de la Gare", org["name"]
  end

  test "homepage has page title" do
    get "/en"
    assert_response :success
    assert_select "title", /Agence Immobili.*1942/
  end

  # --- Property listing SEO ---

  test "property listing has canonical URL without query params" do
    get "/en/sales"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en/sales"]'
  end

  test "property listing has hreflang tags" do
    get "/ventes"
    assert_response :success
    assert_select 'link[rel="alternate"][hreflang="fr"]'
    assert_select 'link[rel="alternate"][hreflang="en"]'
    assert_select 'link[rel="alternate"][hreflang="x-default"]'
  end

  test "property listing has meta description" do
    get "/en/sales"
    assert_response :success
    assert_select 'meta[name="description"]' do |elements|
      assert elements.first["content"].present?
    end
  end

  test "property listing has breadcrumb JSON-LD" do
    get "/en/sales"
    assert_response :success
    scripts = css_select('script[type="application/ld+json"]')
    json_contents = scripts.map { |s| JSON.parse(s.text) }
    breadcrumb = json_contents.find { |j| j["@type"] == "BreadcrumbList" }
    assert_not_nil breadcrumb
    assert breadcrumb["itemListElement"].size >= 2
  end

  # --- Property detail SEO ---

  test "property detail has canonical URL" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    assert_select "link[rel=\"canonical\"][href=\"https://agencegaremonaco.com/en/properties/#{@property.id}-luxury-apartment\"]"
  end

  test "property detail has hreflang tags with locale-specific slugs" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    assert_select "link[rel=\"alternate\"][hreflang=\"fr\"][href*=\"/biens/#{@property.id}-\"]"
    assert_select "link[rel=\"alternate\"][hreflang=\"en\"][href*=\"/en/properties/#{@property.id}-\"]"
  end

  test "property detail has meta description from property description" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    assert_select 'meta[name="description"]' do |elements|
      assert_includes elements.first["content"], "stunning apartment"
    end
  end

  test "property detail has Open Graph with image" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    assert_select 'meta[property="og:image"]' do |elements|
      assert_includes elements.first["content"], "cdn.example.com"
    end
  end

  test "property detail has RealEstateListing JSON-LD" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    scripts = css_select('script[type="application/ld+json"]')
    json_contents = scripts.map { |s| JSON.parse(s.text) }
    listing = json_contents.find { |j| j["@type"] == "RealEstateListing" }
    assert_not_nil listing
    assert_equal "Luxury Apartment", listing["name"]
    assert_equal 2_500_000, listing["offers"]["price"]
  end

  test "property detail has title with price" do
    get "/en/properties/#{@property.id}-luxury-apartment"
    assert_response :success
    assert_select "title", /Luxury Apartment.*2\.500\.000.*Agence Immobilière de la Gare/
  end

  # --- Article SEO ---

  test "article has canonical URL" do
    get "/en/articles/market-trends-2025"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en/articles/market-trends-2025"]'
  end

  test "article has Article JSON-LD" do
    get "/en/articles/market-trends-2025"
    assert_response :success
    scripts = css_select('script[type="application/ld+json"]')
    json_contents = scripts.map { |s| JSON.parse(s.text) }
    article = json_contents.find { |j| j["@type"] == "Article" }
    assert_not_nil article
    assert_equal "Market Trends 2025", article["headline"]
  end

  test "article has og:type article" do
    get "/en/articles/market-trends-2025"
    assert_response :success
    assert_select 'meta[property="og:type"][content="article"]'
  end

  test "articles index has canonical URL" do
    get "/en/articles"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en/articles"]'
  end

  # --- Contact & Privacy SEO ---

  test "contact page has canonical URL" do
    get "/en/contact"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en/contact"]'
  end

  test "privacy page has canonical URL" do
    get "/en/privacy"
    assert_response :success
    assert_select 'link[rel="canonical"][href="https://agencegaremonaco.com/en/privacy"]'
  end

  # --- HTML lang attribute ---

  test "html lang attribute matches locale" do
    get "/de"
    assert_response :success
    assert_select 'html[lang="de"]'
  end
end
