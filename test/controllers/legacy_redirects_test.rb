require "test_helper"

class LegacyRedirectsTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @category = Category.create!(name: "Actualités", slug: "actualites")
    @property = Property.create!(
      reference: "REF-LEGACY",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or", "it" => "Studio Carré d'Or" },
      description: { "fr" => "Un beau studio", "en" => "A beautiful studio", "it" => "Un bel monolocale" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      immotoolbox_id: 12345
    )
    @article = Article.create!(
      title: { "fr" => "Mon article test" },
      body: { "fr" => "Le contenu de l'article" },
      slug: "mon-article-test",
      category: @category,
      published: true,
      published_at: Time.current
    )
  end

  # === French Legacy Routes ===

  test "FR legacy /fr/location/monaco redirects to /fr/locations/monaco" do
    get "/fr/location/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/fr/locations/monaco"
  end

  test "FR legacy /fr/bien/{id} redirects to property detail" do
    get "/fr/bien/12345"
    assert_response :moved_permanently
    assert_redirected_to "/fr/biens/#{@property.id}-studio-carre-d-or"
  end

  test "FR legacy /fr/bien/{id} returns 410 when property not found" do
    get "/fr/bien/99999"
    assert_response :gone
  end

  test "FR legacy /fr/bien-off-market/{id} redirects to property detail when published" do
    get "/fr/bien-off-market/12345"
    assert_response :moved_permanently
    assert_redirected_to "/fr/biens/#{@property.id}-studio-carre-d-or"
  end

  test "FR legacy /fr/bien-off-market/{id} returns 410 when not found" do
    get "/fr/bien-off-market/99999"
    assert_response :gone
  end

  test "FR legacy /fr/articles/ (with trailing slash) redirects to /fr/articles" do
    get "/fr/articles/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/articles"
  end

  test "FR legacy /fr/posts/{category} redirects to articles with category" do
    get "/fr/posts/actualites"
    assert_response :moved_permanently
    assert_redirected_to "/fr/articles/actualites"
  end

  test "FR legacy /fr/posts/{category}/ with trailing slash strips slash first" do
    get "/fr/posts/actualites/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/posts/actualites"
  end

  test "FR legacy /fr/article/{id}/{slug} redirects to article" do
    get "/fr/article/42/mon-article-test"
    assert_response :moved_permanently
    assert_redirected_to "/fr/articles/mon-article-test"
  end

  test "FR legacy /fr/article/{id}/{slug}/ with trailing slash strips slash first" do
    get "/fr/article/42/mon-article-test/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/article/42/mon-article-test"
  end

  test "FR legacy /fr/post/{id}/{slug} redirects to article" do
    get "/fr/post/42/mon-article-test"
    assert_response :moved_permanently
    assert_redirected_to "/fr/articles/mon-article-test"
  end

  test "FR legacy /fr/recherche/{location} redirects to district when match" do
    get "/fr/recherche/carre-dor"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes/monaco/carre-dor"
  end

  test "FR legacy /fr/recherche/{location} redirects to sales monaco when no district match" do
    get "/fr/recherche/unknown-area"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes/monaco"
  end

  # === English Legacy Routes ===

  test "EN legacy /en/rental/monaco redirects to /en/rentals/monaco" do
    get "/en/rental/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/en/rentals/monaco"
  end

  test "EN legacy /en/property/{id} redirects to property detail" do
    get "/en/property/12345"
    assert_response :moved_permanently
    assert_redirected_to "/en/properties/#{@property.id}-studio-carre-d-or"
  end

  test "EN legacy /en/property/{id} returns 410 when property not found" do
    get "/en/property/99999"
    assert_response :gone
  end

  test "EN legacy /en/properties-off-market/sale redirects to sales monaco" do
    get "/en/properties-off-market/sale"
    assert_response :moved_permanently
    assert_redirected_to "/en/sales/monaco"
  end

  test "EN legacy /en/properties-off-market/rental redirects to rentals monaco" do
    get "/en/properties-off-market/rental"
    assert_response :moved_permanently
    assert_redirected_to "/en/rentals/monaco"
  end

  test "EN legacy /en/news redirects to /en/articles" do
    get "/en/news"
    assert_response :moved_permanently
    assert_redirected_to "/en/articles"
  end

  test "EN legacy /en/article/{id}/{slug} redirects to article" do
    get "/en/article/42/mon-article-test"
    assert_response :moved_permanently
    assert_redirected_to "/en/articles/mon-article-test"
  end

  # === Italian Legacy Routes ===

  test "IT legacy /it/affitto/monaco redirects to /it/affitti/monaco" do
    get "/it/affitto/monaco"
    assert_response :moved_permanently
    assert_redirected_to "/it/affitti/monaco"
  end

  test "IT legacy /it/immobile/{id} redirects to property detail" do
    get "/it/immobile/12345"
    assert_response :moved_permanently
    assert_redirected_to "/it/immobili/#{@property.id}-studio-carre-d-or"
  end

  test "IT legacy /it/immobile/{id} returns 410 when property not found" do
    get "/it/immobile/99999"
    assert_response :gone
  end

  # === PDF Legacy Routes ===

  test "FR legacy /fr/pdf-download/{id}.pdf redirects to property detail" do
    get "/fr/pdf-download/12345.pdf"
    assert_response :moved_permanently
    assert_redirected_to "/fr/biens/#{@property.id}-studio-carre-d-or"
  end

  test "FR legacy /fr/pdf-download-nologo/{id}.pdf redirects to property detail" do
    get "/fr/pdf-download-nologo/12345.pdf"
    assert_response :moved_permanently
    assert_redirected_to "/fr/biens/#{@property.id}-studio-carre-d-or"
  end

  # === Trailing Slash Redirects ===

  test "trailing slash on sales route redirects without slash" do
    get "/fr/ventes/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes"
  end

  test "trailing slash on sales monaco route redirects without slash" do
    get "/fr/ventes/monaco/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes/monaco"
  end

  test "trailing slash on property detail route redirects without slash" do
    get "/fr/biens/#{@property.id}-studio-carre-d-or/"
    assert_response :moved_permanently
    assert_redirected_to "/fr/biens/#{@property.id}-studio-carre-d-or"
  end

  test "trailing slash on contact route redirects without slash" do
    get "/en/contact/"
    assert_response :moved_permanently
    assert_redirected_to "/en/contact"
  end

  # === Edge Cases ===

  test "legacy property URL with unpublished property returns 410" do
    @property.update!(published: false)
    get "/fr/bien/12345"
    assert_response :gone
  end

  test "legacy French search with matching district slug" do
    District.create!(name: "Fontvieille", city: "Monaco", slug: "fontvieille")
    get "/fr/recherche/fontvieille"
    assert_response :moved_permanently
    assert_redirected_to "/fr/ventes/monaco/fontvieille"
  end

  test "FR legacy /fr/posts/{category}/ without trailing slash also redirects" do
    get "/fr/posts/actualites"
    assert_response :moved_permanently
    assert_redirected_to "/fr/articles/actualites"
  end
end
