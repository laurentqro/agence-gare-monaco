require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
  end

  test "valid article" do
    article = Article.new(
      title: { "fr" => "Le marché immobilier", "en" => "The real estate market" },
      body: { "fr" => "Contenu de l'article", "en" => "Article content" },
      slug: "le-marche-immobilier",
      category: @category,
      published: true,
      published_at: Time.current
    )
    assert article.valid?
  end

  test "requires slug when title has no generatable text" do
    article = Article.new(
      title: nil,
      body: { "fr" => "Content" },
      category: @category
    )
    assert_not article.valid?
    assert_includes article.errors[:slug], "can't be blank"
  end

  test "auto-generates slug from French title when slug is blank" do
    article = Article.new(
      title: { "fr" => "Le marché immobilier" },
      body: { "fr" => "Content" },
      category: @category
    )
    assert article.valid?
    assert_equal "le-marche-immobilier", article.slug
  end

  test "slug is unique" do
    Article.create!(title: { "fr" => "Test" }, body: { "fr" => "Content" }, slug: "test-article", category: @category)
    duplicate = Article.new(title: { "fr" => "Test 2" }, body: { "fr" => "Content 2" }, slug: "test-article", category: @category)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "belongs to category" do
    assert_equal :belongs_to, Article.reflect_on_association(:category).macro
  end

  test "title is stored as JSON" do
    article = Article.create!(
      title: { "fr" => "Titre", "en" => "Title" },
      body: { "fr" => "Contenu" },
      slug: "test",
      category: @category
    )
    article.reload
    assert_equal "Titre", article.title["fr"]
    assert_equal "Title", article.title["en"]
  end

  test "body is stored as JSON" do
    article = Article.create!(
      title: { "fr" => "Titre" },
      body: { "fr" => "Contenu français", "en" => "English content" },
      slug: "test",
      category: @category
    )
    article.reload
    assert_equal "Contenu français", article.body["fr"]
  end

  test "defaults published to false" do
    article = Article.create!(
      title: { "fr" => "Titre" },
      body: { "fr" => "Contenu" },
      slug: "test",
      category: @category
    )
    assert_equal false, article.published
  end

  test "defaults featured to false" do
    article = Article.create!(
      title: { "fr" => "Titre" },
      body: { "fr" => "Contenu" },
      slug: "test",
      category: @category
    )
    assert_equal false, article.featured
  end

  test "scope published returns only published articles" do
    Article.create!(title: { "fr" => "Pub" }, body: { "fr" => "C" }, slug: "pub", category: @category, published: true, published_at: Time.current)
    Article.create!(title: { "fr" => "Draft" }, body: { "fr" => "C" }, slug: "draft", category: @category, published: false)
    assert_equal 1, Article.published.count
    assert_equal "pub", Article.published.first.slug
  end

  test "scope featured returns only featured articles" do
    Article.create!(title: { "fr" => "Feat" }, body: { "fr" => "C" }, slug: "feat", category: @category, featured: true)
    Article.create!(title: { "fr" => "Norm" }, body: { "fr" => "C" }, slug: "norm", category: @category, featured: false)
    assert_equal 1, Article.featured.count
    assert_equal "feat", Article.featured.first.slug
  end

  test "first_image_url extracts first markdown image URL" do
    article = Article.new(
      body: { "fr" => "Some text\n\n![Photo](https://example.com/photo.jpg)\n\nMore text" },
      category: @category
    )
    assert_equal "https://example.com/photo.jpg", article.first_image_url
  end

  test "first_image_url returns nil when no image in body" do
    article = Article.new(
      body: { "fr" => "Just plain text, no images here" },
      category: @category
    )
    assert_nil article.first_image_url
  end

  test "first_image_url returns nil when body is nil" do
    article = Article.new(body: nil, category: @category)
    assert_nil article.first_image_url
  end

  test "first_image_url extracts first image when multiple exist" do
    article = Article.new(
      body: { "fr" => "![First](https://example.com/first.jpg)\n\n![Second](https://example.com/second.jpg)" },
      category: @category
    )
    assert_equal "https://example.com/first.jpg", article.first_image_url
  end

  # cover_image_display_url
  test "cover_image_display_url returns cover_image_url when set" do
    article = Article.new(
      body: { "fr" => "![Photo](https://example.com/body.jpg)" },
      cover_image_url: "https://example.com/cover.jpg",
      category: @category
    )
    assert_equal "https://example.com/cover.jpg", article.cover_image_display_url
  end

  test "cover_image_display_url falls back to first_image_url when cover_image_url blank" do
    article = Article.new(
      body: { "fr" => "![Photo](https://example.com/body.jpg)" },
      cover_image_url: nil,
      category: @category
    )
    assert_equal "https://example.com/body.jpg", article.cover_image_display_url
  end

  test "cover_image_display_url returns nil when no images at all" do
    article = Article.new(
      body: { "fr" => "No images here" },
      cover_image_url: nil,
      category: @category
    )
    assert_nil article.cover_image_display_url
  end

  # title_for falls back past empty strings
  test "title_for skips empty string and falls back to French" do
    article = Article.new(
      title: { "fr" => "Titre français", "it" => "" },
      body: { "fr" => "Contenu" },
      category: @category
    )
    assert_equal "Titre français", article.title_for(:it)
  end

  test "title_for skips whitespace-only string and falls back to French" do
    article = Article.new(
      title: { "fr" => "Titre français", "it" => "   " },
      body: { "fr" => "Contenu" },
      category: @category
    )
    assert_equal "Titre français", article.title_for(:it)
  end

  # body_for falls back past empty strings
  test "body_for skips empty string and falls back to French" do
    article = Article.new(
      title: { "fr" => "Titre" },
      body: { "fr" => "Contenu français", "it" => "" },
      category: @category
    )
    assert_equal "Contenu français", article.body_for(:it)
  end

  test "body_for skips whitespace-only string and falls back to French" do
    article = Article.new(
      title: { "fr" => "Titre" },
      body: { "fr" => "Contenu français", "it" => "   " },
      category: @category
    )
    assert_equal "Contenu français", article.body_for(:it)
  end

  # body_image_urls
  test "body_image_urls returns all image URLs from body" do
    article = Article.new(
      body: { "fr" => "![First](https://example.com/a.jpg)\n\ntext\n\n![Second](https://example.com/b.jpg)" },
      category: @category
    )
    assert_equal [ "https://example.com/a.jpg", "https://example.com/b.jpg" ], article.body_image_urls
  end

  test "body_image_urls returns empty array when no images" do
    article = Article.new(
      body: { "fr" => "Just text" },
      category: @category
    )
    assert_equal [], article.body_image_urls
  end

  # translated_at
  test "translated_at parses ISO8601 timestamp from translations_status" do
    article = Article.new(
      title: { "fr" => "T" },
      body: { "fr" => "B" },
      category: @category,
      translations_status: { "en" => { "translated_at" => "2026-04-29T10:15:00Z" } }
    )
    expected = Time.iso8601("2026-04-29T10:15:00Z")
    assert_equal expected, article.translated_at(:en)
  end

  test "translated_at returns nil when locale is missing" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: { "en" => { "translated_at" => "2026-04-29T10:15:00Z" } }
    )
    assert_nil article.translated_at(:de)
  end

  test "translated_at returns nil when translations_status is empty hash" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: {}
    )
    assert_nil article.translated_at(:en)
  end

  test "translated_at returns nil when timestamp is unparseable" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: { "en" => { "translated_at" => "not a date" } }
    )
    assert_nil article.translated_at(:en)
  end

  # translation_error
  test "translation_error returns the _error hash when present" do
    err = { "class" => "RubyLLM::ContextLengthExceededError", "message" => "too long", "failed_at" => "2026-04-29T10:00:00Z" }
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: { "_error" => err }
    )
    assert_equal err, article.translation_error
  end

  test "translation_error returns nil when _error is absent" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: { "en" => { "translated_at" => "2026-04-29T10:15:00Z" } }
    )
    assert_nil article.translation_error
  end

  test "translation_error returns nil when _error has no class key" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: { "_error" => { "message" => "orphan" } }
    )
    assert_nil article.translation_error
  end

  # translated_count
  test "translated_count returns 0 when translations_status is empty" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: {}
    )
    assert_equal 0, article.translated_count
  end

  test "translated_count returns the number of non-FR locales with a translated_at" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: {
        "en" => { "translated_at" => "2026-04-29T10:00:00Z" },
        "it" => { "translated_at" => "2026-04-29T10:00:00Z" },
        "de" => { "translated_at" => "2026-04-29T10:00:00Z" }
      }
    )
    assert_equal 3, article.translated_count
  end

  test "translated_count ignores _error key" do
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: {
        "en" => { "translated_at" => "2026-04-29T10:00:00Z" },
        "_error" => { "class" => "X" }
      }
    )
    assert_equal 1, article.translated_count
  end

  test "translated_count returns 8 when all target locales are translated" do
    status = {}
    %w[en it de sv no da fi ru].each do |loc|
      status[loc] = { "translated_at" => "2026-04-29T10:00:00Z" }
    end
    article = Article.new(
      title: { "fr" => "T" }, body: { "fr" => "B" }, category: @category,
      translations_status: status
    )
    assert_equal 8, article.translated_count
  end
end
