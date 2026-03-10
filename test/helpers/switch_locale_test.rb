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

  test "switching locale from article show page preserves slug" do
    category = Category.create!(name: { "fr" => "Test" }, slug: "test-category")
    article = Article.create!(
      title: { "fr" => "Mon Article", "en" => "My Article", "it" => "Mio Articolo" },
      body: { "fr" => "Contenu", "en" => "Content", "it" => "Contenuto" },
      slug: "mon-article",
      category: category,
      published: true,
      published_at: 1.day.ago
    )

    get "/en/articles/#{article.slug}"
    assert_response :success
    # French article
    assert_select "a[href='/articles/#{article.slug}']"
    # Italian article
    assert_select "a[href='/it/articoli/#{article.slug}']"
  end

  # === Sales listings ===

  test "switching locale from EN sales monaco goes to translated sales monaco" do
    get "/en/sales/monaco"
    assert_response :success
    # French
    assert_select "a[href='/ventes/monaco']"
    # Italian
    assert_select "a[href='/it/vendite/monaco']"
  end

  # === Sales with district ===

  test "switching locale from sales monaco district preserves district slug" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 999)

    get "/en/sales/monaco/#{district.slug}"
    assert_response :success
    # French
    assert_select "a[href='/ventes/monaco/#{district.slug}']"
    # Italian
    assert_select "a[href='/it/vendite/monaco/#{district.slug}']"
  end

  # === Rentals ===

  test "switching locale from EN rentals monaco goes to translated rentals" do
    get "/en/rentals/monaco"
    assert_response :success
    # French
    assert_select "a[href='/locations/monaco']"
    # Italian
    assert_select "a[href='/it/affitti/monaco']"
  end

  # === Sales France ===

  test "switching locale from EN sales france goes to translated path" do
    get "/en/sales/france"
    assert_response :success
    # French
    assert_select "a[href='/ventes/france']"
    # German
    assert_select "a[href='/de/verkauf/frankreich']"
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
