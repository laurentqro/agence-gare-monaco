require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  setup do
    @category = Category.create!(name: "Actualités", slug: "actualites")
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
end
