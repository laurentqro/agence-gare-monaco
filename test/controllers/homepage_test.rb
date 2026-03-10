require "test_helper"

class HomepageTest < ActionDispatch::IntegrationTest
  # === French homepage served at / (no /fr prefix) ===

  test "root URL serves French homepage directly" do
    get "/"
    assert_response :success
    assert_select "[data-testid='hero']"
  end

  test "/fr redirects to / with 301" do
    get "/fr"
    assert_redirected_to "/"
    assert_response :moved_permanently
  end

  test "language switcher links to / for French" do
    get "/"
    assert_select "a[href='/']", minimum: 1
  end

  # === Hero Section ===

  test "homepage displays hero section with tagline" do
    get "/"
    assert_response :success
    assert_select "[data-testid='hero'] h1", text: /Monaco/
  end

  test "homepage hero displays subtitle" do
    get "/"
    assert_select "[data-testid='hero'] p", text: /1942/
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

  # === Hero Service Cards ===

  test "homepage hero displays five service cards" do
    get "/"
    assert_select "[data-testid='hero-cards'] a.hero-card", 5
  end

  test "hero cards link to correct paths for French" do
    get "/"
    assert_select "[data-testid='hero-cards']" do
      assert_select "a[href='/ventes']", 1
      assert_select "a[href='/locations']", 1
      assert_select "a[href='/off-market']", 1
      assert_select "a[href='/vendre']", 1
      assert_select "a[href='/gestion']", 1
    end
  end

  test "hero cards link to correct paths for English" do
    get "/en"
    assert_select "[data-testid='hero-cards']" do
      assert_select "a[href='/en/sales']", 1
      assert_select "a[href='/en/rentals']", 1
      assert_select "a[href='/en/off-market']", 1
      assert_select "a[href='/en/sell']", 1
      assert_select "a[href='/en/management']", 1
    end
  end

  test "hero cards display translated labels for French" do
    get "/"
    assert_select "[data-testid='hero-cards']" do
      assert_select "a", text: /Acheter/
      assert_select "a", text: /Louer/
      assert_select "a", text: /Off-market/
      assert_select "a", text: /Vendre/
      assert_select "a", text: /Gestion/
    end
  end

  test "hero cards display translated labels for English" do
    get "/en"
    assert_select "[data-testid='hero-cards']" do
      assert_select "a", text: /Buy/
      assert_select "a", text: /Rent/
      assert_select "a", text: /Off-market/
      assert_select "a", text: /Sell/
      assert_select "a", text: /Management/
    end
  end

  test "hero cards contain SVG icons" do
    get "/"
    assert_select "[data-testid='hero-cards'] svg", 5
  end

  # === About Section ===

  test "homepage displays about section with agency history" do
    get "/"
    assert_select "[data-testid='about']" do
      assert_match "1942", response.body
    end
  end

  test "about section mentions founding story" do
    get "/"
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
    get "/"
    assert_select "[data-testid='team']" do
      assert_match "Pierre Maré", response.body
      assert_match "Adrien Maré", response.body
      assert_match "Josiane Alesi", response.body
    end
  end

  test "team section shows roles" do
    get "/"
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
    get "/"
    assert_select "[data-testid='featured-articles']"
  end

  test "homepage shows featured articles when they exist" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    article = Article.create!(
      title: { "fr" => "Monaco en 2025", "en" => "Monaco in 2025" },
      body: { "fr" => "Les tendances du marché immobilier.", "en" => "Real estate market trends." },
      slug: "monaco-2025",
      category: category,
      published: true,
      featured: true,
      published_at: Time.current
    )

    get "/"
    assert_select "[data-testid='featured-articles']" do
      assert_match "Monaco en 2025", response.body
    end
  end

  test "homepage shows article title in current locale" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
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
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Article brouillon" },
      body: { "fr" => "Pas encore publié." },
      slug: "draft-article",
      category: category,
      published: false,
      featured: true,
      published_at: Time.current
    )

    get "/"
    assert_no_match "Article brouillon", response.body
  end

  test "homepage shows non-featured published articles" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Article normal" },
      body: { "fr" => "Contenu normal." },
      slug: "normal-article",
      category: category,
      published: true,
      featured: false,
      published_at: Time.current
    )

    get "/"
    assert_select "[data-testid='featured-articles']" do
      assert_match "Article normal", response.body
    end
  end

  test "homepage shows at most 4 latest articles in 2-column grid" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    5.times do |i|
      Article.create!(
        title: { "fr" => "Article #{i}" },
        body: { "fr" => "Contenu #{i}" },
        slug: "article-#{i}",
        category: category,
        published: true,
        published_at: i.days.ago
      )
    end

    get "/"
    assert_select "[data-testid='featured-articles'] .article-card-featured", 1
    assert_select "[data-testid='featured-articles'] .article-card", 3
  end

  test "homepage article cards show cover image when present" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Avec image" },
      body: { "fr" => "![Photo](https://example.com/photo.jpg)\n\nContenu" },
      slug: "avec-image",
      category: category,
      published: true,
      published_at: Time.current
    )

    get "/"
    assert_select "[data-testid='featured-articles'] .article-card-featured img[src='https://example.com/photo.jpg']"
  end

  test "homepage article cards prefer cover_image_url over body image" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Cover URL" },
      body: { "fr" => "![Photo](https://example.com/body.jpg)\n\nContenu" },
      slug: "cover-url-test",
      category: category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/cover.jpg"
    )

    get "/"
    assert_select "[data-testid='featured-articles'] .article-card-featured img[src='https://example.com/cover.jpg']"
  end

  test "homepage renders latest article as featured full-width card" do
    category = Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    older = Article.create!(
      title: { "fr" => "Ancien article" },
      body: { "fr" => "Contenu ancien" },
      slug: "ancien",
      category: category,
      published: true,
      published_at: 3.days.ago,
      cover_image_url: "https://example.com/old.jpg"
    )
    latest = Article.create!(
      title: { "fr" => "Dernier article" },
      body: { "fr" => "Contenu récent" },
      slug: "dernier",
      category: category,
      published: true,
      published_at: 1.day.ago,
      cover_image_url: "https://example.com/new.jpg"
    )

    get "/"

    assert_select "[data-testid='featured-articles'] .article-card-featured", count: 1
    assert_select "[data-testid='featured-articles'] .article-card-featured img[src='https://example.com/new.jpg']"
    assert_select "[data-testid='featured-articles'] .article-card", count: 1
  end

  test "homepage article cards show category badge" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Badge test" },
      body: { "fr" => "Contenu" },
      slug: "badge-test",
      category: category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/img.jpg"
    )

    get "/"
    assert_select "[data-testid='featured-articles'] .article-category-badge", text: /Actualités/
  end

  test "homepage article cards show localized date format" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(
      title: { "fr" => "Date test" },
      body: { "fr" => "Contenu" },
      slug: "date-test",
      category: category,
      published: true,
      published_at: Date.new(2024, 6, 15),
      cover_image_url: "https://example.com/img.jpg"
    )

    get "/"
    assert_select "[data-testid='featured-articles'] time", text: /juin 2024/i
  end

  # === Contact Section Removed (form lives on dedicated contact page) ===

  test "homepage does not include a contact form" do
    get "/"
    assert_select "[data-testid='contact-section']", count: 0
    assert_select "form[action*='contact_submissions']", count: 0
  end

  # === Image Carousel ===

  test "homepage displays image carousel section" do
    get "/"
    assert_select "[data-testid='carousel']"
  end

  test "carousel has multiple slides" do
    get "/"
    assert_select "[data-testid='carousel'] [data-testid='carousel-slide']", { minimum: 3 }
  end

  # === Videos Section ===

  test "homepage displays videos section with title" do
    get "/"
    assert_select "[data-testid='videos']" do
      assert_select "h2", text: I18n.t("homepage.videos_title", locale: :fr)
    end
  end

  test "homepage renders video iframes when videos exist" do
    YoutubeVideo.create!(video_id: "abc123", title: "Monaco Tour", published_at: 1.day.ago)
    YoutubeVideo.create!(video_id: "def456", title: "Property Visit", published_at: 2.days.ago)

    get "/"
    assert_select "[data-testid='videos'] iframe[src='https://www.youtube-nocookie.com/embed/abc123']"
    assert_select "[data-testid='videos'] iframe[src='https://www.youtube-nocookie.com/embed/def456']"
  end

  test "homepage shows video titles" do
    YoutubeVideo.create!(video_id: "abc123", title: "Monaco Tour", published_at: 1.day.ago)

    get "/"
    assert_select "[data-testid='videos']" do
      assert_match "Monaco Tour", response.body
    end
  end

  test "homepage displays channel link" do
    YoutubeVideo.create!(video_id: "abc123", title: "Test", published_at: 1.day.ago)

    get "/"
    assert_select "[data-testid='videos'] a[href='#{YoutubeVideo::CHANNEL_URL}']"
  end

  test "homepage shows at most 4 videos" do
    5.times { |i| YoutubeVideo.create!(video_id: "vid#{i}", title: "Video #{i}", published_at: i.days.ago) }

    get "/"
    assert_select "[data-testid='videos'] iframe", 4
  end

  test "homepage videos are in reverse chronological order" do
    YoutubeVideo.create!(video_id: "old", title: "Old Video", published_at: 2.days.ago)
    YoutubeVideo.create!(video_id: "new", title: "New Video", published_at: 1.day.ago)

    get "/"
    iframes = css_select("[data-testid='videos'] iframe")
    srcs = iframes.map { |iframe| iframe["src"] }
    assert_equal "https://www.youtube-nocookie.com/embed/new", srcs.first
    assert_equal "https://www.youtube-nocookie.com/embed/old", srcs.last
  end

  test "homepage videos section degrades gracefully when empty" do
    get "/"
    assert_select "[data-testid='videos']" do
      assert_select "h2", text: I18n.t("homepage.videos_title", locale: :fr)
      assert_select "iframe", 0
    end
  end

  test "homepage renders when @youtube_videos is nil" do
    PagesController.class_eval do
      def home
        @latest_articles = Article.published.order(published_at: :desc).limit(4)
        @youtube_videos = nil
        set_seo(page_type: :homepage)
      end
    end
    get "/"
    assert_response :success
    assert_select "[data-testid='videos']"
  ensure
    PagesController.class_eval do
      def home
        @latest_articles = Article.published.order(published_at: :desc).limit(4)
        @youtube_videos = YoutubeVideo.latest
        set_seo(page_type: :homepage)
      end
    end
  end

  # === Team Photo ===

  test "homepage displays team photo before about section" do
    get "/"
    assert_select "[data-testid='team-photo'] img"
  end

  # === All Locales Render ===

  test "homepage renders successfully for all 8 locales" do
    get "/"
    assert_response :success, "Homepage failed for locale fr"
    assert_select "[data-testid='hero']", { minimum: 1 }, "Missing hero for locale fr"

    %w[en it de sv no da fi].each do |locale|
      get "/#{locale}"
      assert_response :success, "Homepage failed for locale #{locale}"
      assert_select "[data-testid='hero']", { minimum: 1 }, "Missing hero for locale #{locale}"
      assert_select "[data-testid='hero-cards']", { minimum: 1 }, "Missing hero cards for locale #{locale}"
      assert_select "[data-testid='about']", { minimum: 1 }, "Missing about section for locale #{locale}"
      assert_select "[data-testid='team']", { minimum: 1 }, "Missing team section for locale #{locale}"
    end
  end

  # === Navbar Transparency on Homepage ===

  test "homepage navbar has white background" do
    get "/"
    assert_select "nav.bg-white"
  end
end
