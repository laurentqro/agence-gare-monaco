require "test_helper"

class ArticlesTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    @published_article = Article.create!(
      title: { "fr" => "Marché immobilier", "en" => "Real estate market" },
      body: { "fr" => "Le marché est en hausse.", "en" => "The market is rising." },
      slug: "marche-immobilier",
      category: @category,
      published: true,
      published_at: 1.day.ago
    )
    @draft_article = Article.create!(
      title: { "fr" => "Brouillon" },
      body: { "fr" => "Pas encore publié" },
      slug: "brouillon",
      category: @category,
      published: false
    )
  end

  # INDEX
  test "GET articles index shows published articles" do
    get "/en/articles"
    assert_response :success
    assert_select "h1", /Articles/
    assert_select "a", /Real estate market/
  end

  test "GET articles index does not show draft articles" do
    get "/en/articles"
    assert_response :success
    assert_select "a", text: /Brouillon/, count: 0
  end

  test "GET articles index shows article category in current locale" do
    get "/en/articles"
    assert_response :success
    assert_select ".article-meta", /News/
  end

  test "GET articles index shows article date" do
    get "/en/articles"
    assert_response :success
    # Published article should show its published_at date
    assert_select "time"
  end

  test "GET articles index works with French locale" do
    get "/articles"
    assert_response :success
    assert_select "a", /Marché immobilier/
  end

  test "GET articles index works with German locale" do
    get "/de/artikel"
    assert_response :success
  end

  # SHOW - article by slug
  test "GET article show renders published article" do
    get "/en/articles/marche-immobilier"
    assert_response :success
    assert_select "h1", /Real estate market/
  end

  test "GET article show displays body in current locale" do
    get "/en/articles/marche-immobilier"
    assert_response :success
    assert_select "div.article-body", /The market is rising/
  end

  test "GET article show displays body in French locale" do
    get "/articles/marche-immobilier"
    assert_response :success
    assert_select "div.article-body", /Le marché est en hausse/
  end

  test "GET article show returns 404 for draft article" do
    get "/en/articles/brouillon"
    assert_response :not_found
  end

  test "GET article show returns 404 for non-existent slug" do
    get "/en/articles/does-not-exist"
    assert_response :not_found
  end

  test "GET article show displays category name in current locale" do
    get "/en/articles/marche-immobilier"
    assert_response :success
    assert_select "a", /News/
  end

  test "GET article show displays published date" do
    get "/en/articles/marche-immobilier"
    assert_response :success
    assert_select "time"
  end

  # SHOW - category filtering
  test "GET articles with localized category slug shows category articles" do
    other_cat = Category.create!(name: { "fr" => "Quartiers", "en" => "Districts" }, slug: "quartiers")
    Article.create!(
      title: { "en" => "Quartier article" },
      body: { "en" => "About quartiers" },
      slug: "quartier-article",
      category: other_cat,
      published: true,
      published_at: Time.current
    )
    get "/en/articles/news"
    assert_response :success
    assert_select "a", /Real estate market/
    assert_select "a", text: /Quartier article/, count: 0
  end

  test "GET articles with localized category slug shows category name in heading" do
    get "/en/articles/news"
    assert_response :success
    assert_select "h1", /News/
  end

  test "GET articles with French category slug works without prefix" do
    get "/articles/actualites"
    assert_response :success
    assert_select "h1", /Actualités/
  end

  # Pagination
  test "GET articles index orders by published_at descending" do
    Article.create!(
      title: { "en" => "Older" },
      body: { "en" => "C" },
      slug: "older",
      category: @category,
      published: true,
      published_at: 1.week.ago
    )
    Article.create!(
      title: { "en" => "Newer" },
      body: { "en" => "C" },
      slug: "newer",
      category: @category,
      published: true,
      published_at: 1.hour.ago
    )
    get "/en/articles"
    assert_response :success
    body = response.body
    newer_pos = body.index("Newer")
    older_pos = body.index("Older")
    assert newer_pos < older_pos, "Newer article should appear before older article"
  end

  # Article model helpers
  test "article title_for returns locale title with fallback" do
    article = Article.new(title: { "fr" => "Titre français", "en" => "English title" })
    assert_equal "English title", article.title_for(:en)
    assert_equal "Titre français", article.title_for(:fr)
    assert_equal "Titre français", article.title_for(:de) # fallback to fr
  end

  test "article body_for returns locale body with fallback" do
    article = Article.new(body: { "fr" => "Corps français", "en" => "English body" })
    assert_equal "English body", article.body_for(:en)
    assert_equal "Corps français", article.body_for(:fr)
    assert_equal "Corps français", article.body_for(:de)
  end

  test "article auto-generates slug from French title before validation" do
    article = Article.new(
      title: { "fr" => "Le marché de Monaco en 2024" },
      body: { "fr" => "Content" },
      category: @category
    )
    article.valid?
    assert_equal "le-marche-de-monaco-en-2024", article.slug
  end

  test "article does not overwrite manually set slug" do
    article = Article.new(
      title: { "fr" => "Le marché" },
      body: { "fr" => "Content" },
      slug: "custom-slug",
      category: @category
    )
    article.valid?
    assert_equal "custom-slug", article.slug
  end
end
