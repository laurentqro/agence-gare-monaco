require "test_helper"

class SeedsTest < ActiveSupport::TestCase
  EXPECTED_CATEGORIES = [
    { name: "Marché immobilier", slug: "marche-immobilier" },
    { name: "Guides pratiques", slug: "guides-pratiques" },
    { name: "Quartiers de Monaco", slug: "quartiers-de-monaco" },
    { name: "Projets & Nouveautés", slug: "projets-et-nouveautes" },
    { name: "Art de vivre à Monaco", slug: "art-de-vivre-a-monaco" },
    { name: "Décoration & Architecture", slug: "decoration-et-architecture" },
    { name: "Actualités", slug: "actualites" }
  ].freeze

  EXPECTED_ARTICLES = {
    "5-raisons-de-vivre-dans-la-principaute-de-monaco" => {
      title: "5 raisons de vivre dans la Principauté de Monaco",
      category_slug: "art-de-vivre-a-monaco",
      date: "2022-01-17"
    },
    "les-avantages-uniques-du-systeme-fiscal-de-monaco" => {
      title: "Les avantages uniques du système fiscal de Monaco",
      category_slug: "guides-pratiques",
      date: "2022-01-17"
    },
    "comment-estimer-la-valeur-de-votre-bien-immobilier-a-monaco" => {
      title: "Comment estimer la valeur de votre bien immobilier à Monaco ?",
      category_slug: "marche-immobilier",
      date: "2022-01-17"
    },
    "comment-vendre-son-bien-immobilier-a-monaco" => {
      title: "Comment vendre son bien immobilier à Monaco ?",
      category_slug: "guides-pratiques",
      date: "2022-01-17"
    },
    "notre-guide-d-achat-de-bien-immobilier-a-monaco" => {
      title: "Notre guide d'achat de bien immobilier à Monaco",
      category_slug: "guides-pratiques",
      date: "2022-01-17"
    },
    "comment-assurer-la-gestion-locative-de-son-bien-immobilier-a-monaco" => {
      title: "Comment assurer la gestion locative de son bien immobilier à Monaco ?",
      category_slug: "guides-pratiques",
      date: "2022-01-17"
    },
    "la-securite-et-la-sante-a-monaco" => {
      title: "La sécurité et la santé à Monaco",
      category_slug: "art-de-vivre-a-monaco",
      date: "2022-01-17"
    },
    "quelles-sont-les-conditions-a-remplir-pour-s-installer-a-monaco" => {
      title: "Quelles sont les conditions à remplir pour s'installer à Monaco ?",
      category_slug: "guides-pratiques",
      date: "2022-01-17"
    },
    "quels-sont-les-quartiers-de-monaco-ou-vous-installer" => {
      title: "Quels sont les quartiers de Monaco où vous installer ?",
      category_slug: "quartiers-de-monaco",
      date: "2022-01-31"
    },
    "nouveau-parking-sur-monaco" => {
      title: "Nouveau parking sur Monaco",
      category_slug: "actualites",
      date: "2022-07-11"
    }
  }.freeze

  test "seeds create all 7 categories" do
    load Rails.root.join("db/seeds.rb")

    assert_equal 7, Category.count

    EXPECTED_CATEGORIES.each do |attrs|
      category = Category.find_by(slug: attrs[:slug])
      assert category, "Expected category with slug '#{attrs[:slug]}' to exist"
      assert_equal attrs[:name], category.name_for(:fr)
      assert_equal 8, category.name.keys.size, "Expected 8 locale keys for category '#{attrs[:slug]}'"
    end
  end

  test "seeds create all 10 articles" do
    load Rails.root.join("db/seeds.rb")

    assert_equal 10, Article.count

    EXPECTED_ARTICLES.each do |slug, attrs|
      article = Article.find_by(slug: slug)
      assert article, "Expected article with slug '#{slug}' to exist"
      assert_equal attrs[:title], article.title_for(:fr)
      assert_equal attrs[:category_slug], article.category.slug
      assert_equal Date.parse(attrs[:date]), article.published_at.to_date
      assert article.published, "Article '#{slug}' should be published"
    end
  end

  test "articles have body content" do
    load Rails.root.join("db/seeds.rb")

    Article.find_each do |article|
      body = article.body_for(:fr)
      assert body.present?, "Article '#{article.slug}' should have body content"
      assert body.length > 10, "Article '#{article.slug}' body should not be empty"
    end
  end

  test "seeds are idempotent" do
    2.times { load Rails.root.join("db/seeds.rb") }

    assert_equal 7, Category.count
    assert_equal 10, Article.count
  end

  test "seeds update category names when re-run" do
    load Rails.root.join("db/seeds.rb")

    # Simulate a category whose name was changed (e.g. missing locale)
    category = Category.find_by!(slug: "marche-immobilier")
    category.update!(name: { "fr" => "Old French Name" })

    # Re-run seeds should update the name
    load Rails.root.join("db/seeds.rb")

    category.reload
    assert_equal "Marché immobilier", category.name_for(:fr)
    assert_equal 8, category.name.keys.size, "Expected all 8 locale keys to be restored"
  end
end
