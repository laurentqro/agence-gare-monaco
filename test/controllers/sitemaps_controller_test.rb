require "test_helper"

class SitemapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @property = Property.create!(
      reference: "SM-001",
      title: { "en" => "Test Property", "fr" => "Bien Test" },
      description: { "en" => "Test", "fr" => "Test" },
      price: 1_000_000,
      transaction_type: "sale",
      property_type: "studio",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      off_market: false
    )
    @unpublished = Property.create!(
      reference: "SM-002",
      title: { "en" => "Draft", "fr" => "Brouillon" },
      description: { "en" => "Draft", "fr" => "Brouillon" },
      price: 500_000,
      transaction_type: "sale",
      property_type: "studio",
      country: "MC",
      city: "Monaco",
      published: false,
      off_market: false
    )
    @off_market = Property.create!(
      reference: "SM-003",
      title: { "en" => "Secret", "fr" => "Secret" },
      description: { "en" => "Off-market", "fr" => "Hors marché" },
      price: 2_000_000,
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true,
      off_market: true
    )
    @category = Category.create!(name: { "fr" => "News" }, slug: "news")
    @article = Article.create!(
      title: { "en" => "Test Article", "fr" => "Article Test" },
      body: { "en" => "Body", "fr" => "Corps" },
      slug: "test-article",
      category: @category,
      published: true,
      published_at: Time.zone.now
    )
    @draft_article = Article.create!(
      title: { "en" => "Draft Article", "fr" => "Article Brouillon" },
      body: { "en" => "Draft", "fr" => "Brouillon" },
      slug: "draft-article",
      category: @category,
      published: false
    )
  end

  # --- Sitemap Index ---

  test "sitemap index returns XML" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "sitemap index references per-language sitemaps" do
    get "/sitemap.xml"
    assert_includes response.body, "sitemaps/fr.xml"
    assert_includes response.body, "sitemaps/en.xml"
    assert_includes response.body, "sitemaps/de.xml"
    assert_includes response.body, "sitemaps/it.xml"
    assert_includes response.body, "sitemaps/sv.xml"
    assert_includes response.body, "sitemaps/no.xml"
    assert_includes response.body, "sitemaps/da.xml"
    assert_includes response.body, "sitemaps/fi.xml"
  end

  # --- Per-language Sitemap ---

  test "language sitemap returns XML" do
    get "/sitemaps/en.xml"
    assert_response :success
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "language sitemap includes homepage" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "https://agencegaremonaco.com/en"
  end

  test "language sitemap includes listing pages" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "/en/sales"
    assert_includes response.body, "/en/rentals"
  end

  test "language sitemap includes published property pages" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "/en/properties/#{@property.id}-"
  end

  test "language sitemap excludes unpublished properties" do
    get "/sitemaps/en.xml"
    refute_includes response.body, "/en/properties/#{@unpublished.id}-"
  end

  test "language sitemap excludes off-market properties" do
    get "/sitemaps/en.xml"
    refute_includes response.body, "/en/properties/#{@off_market.id}-"
  end

  test "language sitemap includes published articles" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "/en/articles/test-article"
  end

  test "language sitemap excludes draft articles" do
    get "/sitemaps/en.xml"
    refute_includes response.body, "/en/articles/draft-article"
  end

  test "language sitemap includes hreflang alternates" do
    get "/sitemaps/en.xml"
    assert_includes response.body, 'xhtml:link'
    assert_includes response.body, 'hreflang="fr"'
    assert_includes response.body, 'hreflang="en"'
  end

  test "language sitemap includes contact and privacy pages" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "/en/contact"
    assert_includes response.body, "/en/privacy"
  end

  test "language sitemap includes off-market page" do
    get "/sitemaps/en.xml"
    assert_includes response.body, "/en/off-market"
  end

  test "French sitemap uses translated segments" do
    get "/sitemaps/fr.xml"
    assert_includes response.body, "/ventes"
    assert_includes response.body, "/biens/#{@property.id}-"
    assert_includes response.body, "/articles/test-article"
  end

  test "French sitemap homepage URL uses root path not /fr" do
    get "/sitemaps/fr.xml"
    assert_includes response.body, "<loc>https://agencegaremonaco.com/</loc>"
    refute_includes response.body, "<loc>https://agencegaremonaco.com/fr</loc>"
  end

  test "French sitemap hreflang for French points to root" do
    get "/sitemaps/fr.xml"
    assert_includes response.body, 'hreflang="fr" href="https://agencegaremonaco.com/"'
  end

  test "French sitemap static pages use root prefix not /fr" do
    get "/sitemaps/fr.xml"
    assert_includes response.body, "<loc>https://agencegaremonaco.com/ventes</loc>"
    assert_includes response.body, "<loc>https://agencegaremonaco.com/locations</loc>"
    refute_includes response.body, "<loc>https://agencegaremonaco.com/fr/"
  end
end
