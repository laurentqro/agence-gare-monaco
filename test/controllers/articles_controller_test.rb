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

    assert_select ".article-card img[src='https://example.com/cover.jpg']"
    assert_select ".article-card .article-title", text: /IMAGE ARTICLE/i
    assert_select ".article-card .article-meta", text: /Actualités/
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

    assert_select ".article-card"
    assert_select ".article-card img", count: 0
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
    assert_select ".article-card img[src='https://example.com/cover.jpg']"
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
    assert_select ".article-card img[src='https://example.com/body.jpg']"
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
