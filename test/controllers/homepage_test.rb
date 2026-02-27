require "test_helper"

class HomepageTest < ActionDispatch::IntegrationTest
  # === Hero Section ===

  test "homepage displays hero section with tagline" do
    get "/fr"
    assert_response :success
    assert_select "[data-testid='hero'] h1", text: /1942/
  end

  test "homepage hero displays CIM membership subtitle" do
    get "/fr"
    assert_select "[data-testid='hero'] p", text: /Chambre Immobilière Monégasque/
  end

  test "homepage hero is translated per locale" do
    get "/en"
    assert_select "[data-testid='hero']" do
      assert_match "Real Estate in Monaco since 1942", response.body
    end

    get "/de"
    assert_select "[data-testid='hero']" do
      assert_match "Immobilien in Monaco seit 1942", response.body
    end
  end

  # === Category Cards ===

  test "homepage displays three category cards" do
    get "/fr"
    assert_select "[data-testid='category-cards']" do
      assert_select "a[href='/fr/ventes/monaco']", text: /Ventes Monaco/i
      assert_select "a[href='/fr/locations/monaco']", text: /Location Monaco/i
      assert_select "a[href='/fr/ventes/france']", text: /France/i
    end
  end

  test "category cards link to correct locale-translated paths" do
    get "/en"
    assert_select "[data-testid='category-cards']" do
      assert_select "a[href='/en/sales/monaco']"
      assert_select "a[href='/en/rentals/monaco']"
      assert_select "a[href='/en/sales/france']"
    end
  end

  # === About Section ===

  test "homepage displays about section with agency history" do
    get "/fr"
    assert_select "[data-testid='about']" do
      assert_match "1942", response.body
    end
  end

  test "about section mentions founding story" do
    get "/fr"
    assert_select "[data-testid='about']" do
      assert_match I18n.t("homepage.about_title", locale: :fr), response.body
    end
  end

  test "about section is translated per locale" do
    get "/en"
    assert_select "[data-testid='about']" do
      assert_match I18n.t("homepage.about_title", locale: :en), response.body
    end
  end

  # === Team Section ===

  test "homepage displays team section with three members" do
    get "/fr"
    assert_select "[data-testid='team']" do
      assert_match "Pierre Maré", response.body
      assert_match "Adrien Maré", response.body
      assert_match "Josiane Alesi", response.body
    end
  end

  test "team section shows roles" do
    get "/fr"
    assert_select "[data-testid='team']" do
      assert_match I18n.t("homepage.team.pierre_role", locale: :fr), response.body
      assert_match I18n.t("homepage.team.adrien_role", locale: :fr), response.body
      assert_match I18n.t("homepage.team.josiane_role", locale: :fr), response.body
    end
  end

  test "team roles are translated per locale" do
    get "/en"
    assert_select "[data-testid='team']" do
      assert_match I18n.t("homepage.team.pierre_role", locale: :en), response.body
      assert_match I18n.t("homepage.team.adrien_role", locale: :en), response.body
    end
  end

  # === Featured Articles ===

  test "homepage displays featured articles section" do
    get "/fr"
    assert_select "[data-testid='featured-articles']"
  end

  test "homepage shows featured articles when they exist" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    article = Article.create!(
      title: { "fr" => "Monaco en 2025", "en" => "Monaco in 2025" },
      body: { "fr" => "Les tendances du marché immobilier.", "en" => "Real estate market trends." },
      slug: "monaco-2025",
      category: category,
      published: true,
      featured: true,
      published_at: Time.current
    )

    get "/fr"
    assert_select "[data-testid='featured-articles']" do
      assert_match "Monaco en 2025", response.body
    end
  end

  test "homepage shows article title in current locale" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    Article.create!(
      title: { "fr" => "Titre Français", "en" => "English Title" },
      body: { "fr" => "Contenu en français.", "en" => "English content." },
      slug: "test-article",
      category: category,
      published: true,
      featured: true,
      published_at: Time.current
    )

    get "/en"
    assert_select "[data-testid='featured-articles']" do
      assert_match "English Title", response.body
    end
  end

  test "homepage does not show unpublished articles" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    Article.create!(
      title: { "fr" => "Article brouillon" },
      body: { "fr" => "Pas encore publié." },
      slug: "draft-article",
      category: category,
      published: false,
      featured: true,
      published_at: Time.current
    )

    get "/fr"
    assert_no_match "Article brouillon", response.body
  end

  test "homepage does not show non-featured articles" do
    category = Category.create!(name: "Actualités", slug: "actualites")
    Article.create!(
      title: { "fr" => "Article normal" },
      body: { "fr" => "Contenu normal." },
      slug: "normal-article",
      category: category,
      published: true,
      featured: false,
      published_at: Time.current
    )

    get "/fr"
    assert_select "[data-testid='featured-articles']" do
      assert_no_match "Article normal", response.body
    end
  end

  # === Contact Section ===

  test "homepage displays contact section with agency address" do
    get "/fr"
    assert_select "[data-testid='contact-section']" do
      assert_match "3, Rue Langlé", response.body
      assert_match "MC 98000", response.body
    end
  end

  test "homepage contact section includes phone number" do
    get "/fr"
    assert_select "[data-testid='contact-section']" do
      assert_match "(+377) 93 30 22 36", response.body
    end
  end

  test "homepage contact section includes email" do
    get "/fr"
    assert_select "[data-testid='contact-section'] a[href='mailto:info@agencegaremonaco.com']"
  end

  # === Image Carousel ===

  test "homepage displays image carousel section" do
    get "/fr"
    assert_select "[data-testid='carousel']"
  end

  test "carousel has multiple slides" do
    get "/fr"
    assert_select "[data-testid='carousel'] [data-testid='carousel-slide']", { minimum: 3 }
  end

  # === Videos Section ===

  test "homepage displays videos section placeholder" do
    get "/fr"
    assert_select "[data-testid='videos']"
  end

  # === All Locales Render ===

  test "homepage renders successfully for all 8 locales" do
    %w[fr en it de sv no da fi].each do |locale|
      get "/#{locale}"
      assert_response :success, "Homepage failed for locale #{locale}"
      assert_select "[data-testid='hero']", { minimum: 1 }, "Missing hero for locale #{locale}"
      assert_select "[data-testid='category-cards']", { minimum: 1 }, "Missing category cards for locale #{locale}"
      assert_select "[data-testid='about']", { minimum: 1 }, "Missing about section for locale #{locale}"
      assert_select "[data-testid='team']", { minimum: 1 }, "Missing team section for locale #{locale}"
    end
  end

  # === Navbar Transparency on Homepage ===

  test "homepage navbar is transparent (no solid background on hero)" do
    get "/fr"
    # The navbar on homepage should have transparent styling for hero overlay
    assert_select "nav.homepage-nav-transparent"
  end
end
