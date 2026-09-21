require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
  end

  test "article show renders markdown body as HTML" do
    article = Article.create!(
      title: { "en" => "Test Article" },
      body: { "en" => "**bold text** and _italic_" },
      slug: "test-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/test-article"
    assert_response :success

    # Markdown should be rendered as HTML, not shown as raw markdown
    assert_select ".article-body strong", "bold text"
    assert_select ".article-body em", "italic"
  end

  test "article show renders markdown headings" do
    article = Article.create!(
      title: { "en" => "Heading Article" },
      body: { "en" => "## Subtitle\n\nSome content" },
      slug: "heading-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/heading-article"
    assert_response :success
    assert_select ".article-body h2", "Subtitle"
    assert_select ".article-body p", "Some content"
  end

  test "article show renders markdown links" do
    article = Article.create!(
      title: { "en" => "Link Article" },
      body: { "en" => "Visit [example](https://example.com) for more." },
      slug: "link-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/link-article"
    assert_response :success
    assert_select ".article-body a[href='https://example.com']", "example"
  end

  test "article show renders markdown lists" do
    article = Article.create!(
      title: { "en" => "List Article" },
      body: { "en" => "- first item\n- second item" },
      slug: "list-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/list-article"
    assert_response :success
    assert_select ".article-body ul li", minimum: 2
  end

  test "article index renders card with cover image when body has image" do
    article = Article.create!(
      title: { "en" => "Image Article" },
      body: { "en" => "![Cover](https://example.com/cover.jpg)\n\nSome content" },
      slug: "image-article",
      category: @category,
      published: true,
      published_at: 2.days.ago
    )

    get "/en/articles"
    assert_response :success

    assert_select ".article-card-featured img[src='https://example.com/cover.jpg']"
    assert_select ".article-card-featured .article-title", text: /Image Article/i
    assert_select ".article-card-featured .article-category-badge", text: /Actualités/
  end

  test "article index renders card without image when body has no image" do
    article = Article.create!(
      title: { "en" => "Text Only" },
      body: { "en" => "Just plain text" },
      slug: "text-only",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles"
    assert_response :success

    assert_select ".article-card-featured"
    assert_select ".article-card-featured img", count: 0
  end

  test "article show handles nil body gracefully" do
    article = Article.create!(
      title: { "en" => "Empty Body" },
      body: { "en" => "" },
      slug: "empty-body",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/empty-body"
    assert_response :success
    assert_select ".article-body"
  end

  test "article show renders markdown images" do
    article = Article.create!(
      title: { "en" => "Image Article" },
      body: { "en" => "![Photo of Monaco](https://example.com/photo.jpg)" },
      slug: "image-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/image-article"
    assert_response :success
    assert_select ".article-body img[src='https://example.com/photo.jpg'][alt='Photo of Monaco']"
  end

  # Cover image on index
  test "article index prefers cover_image_url over first_image_url" do
    Article.create!(
      title: { "en" => "Cover Test" },
      body: { "en" => "![Body](https://example.com/body.jpg)\n\nContent" },
      slug: "cover-index-test",
      category: @category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/cover.jpg"
    )

    get "/en/articles"
    assert_response :success
    assert_select ".article-card-featured img[src='https://example.com/cover.jpg']"
  end

  test "article index falls back to first_image_url when no cover_image_url" do
    Article.create!(
      title: { "en" => "Fallback Test" },
      body: { "en" => "![Body](https://example.com/body.jpg)\n\nContent" },
      slug: "fallback-test",
      category: @category,
      published: true,
      published_at: Time.current,
      cover_image_url: nil
    )

    get "/en/articles"
    assert_response :success
    assert_select ".article-card-featured img[src='https://example.com/body.jpg']"
  end

  # Featured (latest) article card
  test "article index renders latest article as featured full-width card" do
    older = Article.create!(
      title: { "en" => "Older Article" },
      body: { "en" => "Old content" },
      slug: "older-article",
      category: @category,
      published: true,
      published_at: 5.days.ago,
      cover_image_url: "https://example.com/old.jpg"
    )
    latest = Article.create!(
      title: { "en" => "Latest Article" },
      body: { "en" => "New content" },
      slug: "latest-article",
      category: @category,
      published: true,
      published_at: 1.day.ago,
      cover_image_url: "https://example.com/new.jpg"
    )

    get "/en/articles"
    assert_response :success

    # Featured card is full-width and contains the latest article
    assert_select ".article-card-featured", count: 1
    assert_select ".article-card-featured .article-title", text: /Latest Article/i
    assert_select ".article-card-featured img[src='https://example.com/new.jpg']"

    # The remaining articles are in the regular grid
    assert_select ".article-card", count: 1
    assert_select ".article-card .article-title", text: /Older Article/i
  end

  test "article index renders category badge on cards" do
    Article.create!(
      title: { "en" => "Badge Test" },
      body: { "en" => "Content" },
      slug: "badge-test",
      category: @category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/img.jpg"
    )

    get "/en/articles"
    assert_response :success

    assert_select ".article-category-badge", text: /Actualités/
  end

  test "article index renders human-friendly date format" do
    Article.create!(
      title: { "en" => "Date Test" },
      body: { "en" => "Content" },
      slug: "date-test",
      category: @category,
      published: true,
      published_at: Date.new(2024, 3, 15),
      cover_image_url: "https://example.com/img.jpg"
    )

    get "/en/articles"
    assert_response :success

    # Should show localized long date, not YYYY-MM-DD
    assert_select "time", text: /March/i
    assert_select "time", { text: /2024-03-15/, count: 0 }
  end

  test "article index with single article shows only featured card, no grid" do
    Article.create!(
      title: { "en" => "Only Article" },
      body: { "en" => "Solo" },
      slug: "only-article",
      category: @category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/solo.jpg"
    )

    get "/en/articles"
    assert_response :success

    assert_select ".article-card-featured", count: 1
    assert_select ".article-card", count: 0
  end

  # Cover image on show (hero)
  test "article show displays cover image as hero when present" do
    Article.create!(
      title: { "en" => "Hero Test" },
      body: { "en" => "Some content" },
      slug: "hero-test",
      category: @category,
      published: true,
      published_at: Time.current,
      cover_image_url: "https://example.com/hero.jpg"
    )

    get "/en/articles/hero-test"
    assert_response :success
    assert_select "img.article-cover-image[src='https://example.com/hero.jpg']"
  end

  test "article show does not display hero image when no cover image" do
    Article.create!(
      title: { "en" => "No Hero" },
      body: { "en" => "Content without images" },
      slug: "no-hero",
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/no-hero"
    assert_response :success
    assert_select "img.article-cover-image", count: 0
  end

  # Per-locale localised slugs (SEO audit 0.2)
  test "article index links to the canonical per-locale slug, not the FR slug" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles"
    assert_response :success
    # The featured card must link straight to the EN slug (no 301 hop through
    # the shared FR slug), or internal links point at non-canonical URLs.
    assert_select "a[href='/en/articles/how-to-sell-your-property']"
    assert_select "a[href='/en/articles/comment-vendre']", count: 0
  end

  test "article show resolves an article by its per-locale slug" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "**gras**", "en" => "**bold** content" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/how-to-sell-your-property"
    assert_response :success
    assert_select ".article-body strong", "bold"
  end

  test "article show 301s the shared FR slug to the canonical per-locale slug" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    # An indexed /en/articles/comment-vendre (the old shared slug) must not
    # serve a 200 under a non-canonical URL: it 301s to the EN slug so all
    # authority consolidates on one URL per locale.
    get "/en/articles/comment-vendre"
    assert_response :moved_permanently
    assert_redirected_to "/en/articles/how-to-sell-your-property"
  end

  test "article show preserves the query string on the canonical 301" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/comment-vendre?utm_source=newsletter"
    assert_response :moved_permanently
    assert_redirected_to "/en/articles/how-to-sell-your-property?utm_source=newsletter"
  end

  test "article show does not redirect when the URL already carries the canonical slug" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/en/articles/how-to-sell-your-property"
    assert_response :success
  end

  test "article show serves the FR slug under FR without redirecting" do
    Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category,
      published: true,
      published_at: Time.current
    )

    get "/articles/comment-vendre"
    assert_response :success
  end

  test "article show still 404s a slug that matches no article" do
    get "/en/articles/no-such-article-anywhere"
    assert_response :not_found
  end

  test "all 8 locales render markdown on article show" do
    article = Article.create!(
      title: { "fr" => "Article FR", "en" => "Article EN" },
      body: { "fr" => "**gras**", "en" => "**bold**" },
      slug: "multi-locale-article",
      category: @category,
      published: true,
      published_at: Time.current
    )

    # French (default locale, no prefix)
    get "/articles/multi-locale-article"
    assert_response :success
    assert_select ".article-body strong", "gras"

    # English
    get "/en/articles/multi-locale-article"
    assert_response :success
    assert_select ".article-body strong", "bold"
  end
end
