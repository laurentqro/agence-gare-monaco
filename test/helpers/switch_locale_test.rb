require "test_helper"

class SwitchLocaleTest < ActionDispatch::IntegrationTest
  setup do
    I18n.locale = :en
  end

  # === Homepage ===

  test "switching locale from FR homepage goes to target locale homepage" do
    get "/"
    assert_response :success
    # Should link to /en for English
    assert_select "a[href='/en']"
    # Should link to /it for Italian
    assert_select "a[href='/it']"
  end

  test "switching locale from EN homepage goes to target locale homepage" do
    get "/en"
    assert_response :success
    # Should link to / for French (not /fr)
    assert_select "a[href='/']"
    # Should link to /it for Italian
    assert_select "a[href='/it']"
  end

  # === Articles index ===

  test "switching locale from EN articles goes to translated articles path" do
    get "/en/articles"
    assert_response :success
    # French articles
    assert_select "a[href='/articles']"
    # Italian articles
    assert_select "a[href='/it/articoli']"
    # German articles
    assert_select "a[href='/de/artikel']"
  end

  test "switching locale from FR articles goes to translated articles path" do
    get "/articles"
    assert_response :success
    # English articles
    assert_select "a[href='/en/articles']"
    # Italian articles
    assert_select "a[href='/it/articoli']"
  end

  # === Article show ===

  test "switching locale from article show page localizes the slug per locale" do
    category = Category.create!(name: { "fr" => "Test" }, slug: "test-category")
    Article.create!(
      title: { "fr" => "Mon Article", "en" => "My Article", "it" => "Mio Articolo" },
      body: { "fr" => "Contenu", "en" => "Content", "it" => "Contenuto" },
      slug: "mon-article",
      slugs: { "en" => "my-article", "it" => "mio-articolo" },
      category: category,
      published: true,
      published_at: 1.day.ago
    )

    get "/en/articles/my-article"
    assert_response :success
    # French article uses the canonical FR slug (unprefixed locale)
    assert_select "a[href='/articles/mon-article']"
    # Italian article uses the Italian slug
    assert_select "a[href='/it/articoli/mio-articolo']"
    # The current-locale (EN) slug must not leak into other locales' links
    assert_select "a[href='/it/articoli/my-article']", count: 0
  end

  test "switching locale from an article falls back to the FR slug when a locale has none" do
    category = Category.create!(name: { "fr" => "Test" }, slug: "test-category")
    Article.create!(
      title: { "fr" => "Mon Article", "en" => "My Article" },
      body: { "fr" => "Contenu", "en" => "Content" },
      slug: "mon-article",
      slugs: { "en" => "my-article" },
      category: category,
      published: true,
      published_at: 1.day.ago
    )

    get "/en/articles/my-article"
    assert_response :success
    # German has no slug of its own: fall back to the canonical FR slug.
    assert_select "a[href='/de/artikel/mon-article']"
  end

  # === Category filter page (served by articles#show) ===

  test "switching locale from a category page localizes the category slug" do
    Category.create!(
      name: {
        "fr" => "Actualités", "en" => "News", "de" => "Aktuelles", "ru" => "Новости"
      },
      slug: "actualites"
    )

    get "/en/articles/news"
    assert_response :success
    # French category (unprefixed locale)
    assert_select "a[href='/articles/actualites']"
    # German category
    assert_select "a[href='/de/artikel/aktuelles']"
    # Russian category, transliterated with Russian rules
    assert_select "a[href='/ru/stati/novosti']"
    # The current-locale slug must not leak into other locales' links
    assert_select "a[href='/de/artikel/news']", count: 0
  end

  test "switching locale from a category page falls back to base slug when locale name missing" do
    Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")

    get "/en/articles/news"
    assert_response :success
    # No Italian name: fall back to the base (French) slug
    assert_select "a[href='/it/articoli/actualites']"
  end

  # === Sales listings ===

  test "switching locale from EN sales goes to translated sales" do
    get "/en/sales"
    assert_response :success
    # French
    assert_select "a[href='/ventes']"
    # Italian
    assert_select "a[href='/it/vendite']"
  end

  # === Rentals ===

  test "switching locale from EN rentals goes to translated rentals" do
    get "/en/rentals"
    assert_response :success
    # French
    assert_select "a[href='/locations']"
    # Italian
    assert_select "a[href='/it/affitti']"
  end

  # === Property detail ===

  test "switching locale from property show preserves property id" do
    property = Property.create!(
      title: { "fr" => "Bel Appart", "en" => "Nice Apt" },
      description: { "fr" => "Desc" },
      property_type: "apartment",
      transaction_type: "sale",
      country: "MC",
      price: 1_000_000,
      immotoolbox_id: 888,
      reference: "REF-888",
      city: "Monaco",
      published: true
    )

    slug = property.title_for(:en).parameterize
    get "/en/properties/#{property.id}-#{slug}"
    assert_response :success

    fr_slug = property.title_for(:fr).parameterize
    assert_select "a[href='/biens/#{property.id}-#{fr_slug}']"
  end

  # === Contact ===

  test "switching locale from EN contact goes to translated contact" do
    get "/en/contact"
    assert_response :success
    # French
    assert_select "a[href='/contact']"
    # Italian
    assert_select "a[href='/it/contatto']"
  end

  # === Privacy ===

  test "switching locale from EN privacy goes to translated privacy" do
    get "/en/privacy"
    assert_response :success
    # French
    assert_select "a[href='/confidentialite']"
  end

  # === Off-market ===

  test "switching locale from EN off-market goes to translated off-market" do
    get "/en/off-market"
    assert_response :success
    # French
    assert_select "a[href='/off-market']"
    # German
    assert_select "a[href='/de/off-market']"
  end
end
