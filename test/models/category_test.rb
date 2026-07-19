require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    category = Category.new(name: { "fr" => "Actualités" }, slug: "actualites")
    assert category.valid?
  end

  test "requires name with at least one non-blank value" do
    category = Category.new(slug: "actualites")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"

    category.name = {}
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"

    category.name = { "fr" => "" }
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires slug" do
    category = Category.new(name: { "fr" => "Actualités" })
    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"
  end

  test "slug is unique" do
    Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    duplicate = Category.new(name: { "fr" => "News" }, slug: "actualites")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "has many articles" do
    assert_equal :has_many, Category.reflect_on_association(:articles).macro
  end

  test "name_for returns locale value" do
    category = Category.new(name: { "fr" => "Actualités", "en" => "News" })
    assert_equal "News", category.name_for(:en)
  end

  test "name_for falls back to French" do
    category = Category.new(name: { "fr" => "Actualités" })
    assert_equal "Actualités", category.name_for(:en)
  end

  test "name_for falls back to first value" do
    category = Category.new(name: { "en" => "News" })
    assert_equal "News", category.name_for(:de)
  end

  test "name_for defaults to current locale" do
    category = Category.new(name: { "fr" => "Actualités", "en" => "News" })
    I18n.with_locale(:en) do
      assert_equal "News", category.name_for
    end
  end

  test "slug_for returns parameterized locale name" do
    category = Category.new(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    assert_equal "news", category.slug_for(:en)
    assert_equal "actualites", category.slug_for(:fr)
  end

  test "slug_for transliterates with the target locale's rules regardless of runtime locale" do
    category = Category.new(name: { "fr" => "Actualités", "ru" => "Новости" }, slug: "actualites")
    I18n.with_locale(:de) do
      assert_equal "novosti", category.slug_for(:ru)
    end
  end

  test "find_by_localized_slug finds Cyrillic-derived slug regardless of runtime locale" do
    category = Category.create!(name: { "fr" => "Actualités", "ru" => "Новости" }, slug: "actualites")
    I18n.with_locale(:fr) do
      assert_equal category, Category.find_by_localized_slug("novosti", :ru)
    end
  end

  test "slug_for falls back to base slug" do
    category = Category.new(name: { "fr" => "Actualités" }, slug: "actualites")
    assert_equal "actualites", category.slug_for(:de)
  end

  test "find_by_localized_slug finds by locale-specific slug" do
    category = Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    assert_equal category, Category.find_by_localized_slug("news", :en)
    assert_equal category, Category.find_by_localized_slug("actualites", :fr)
  end

  test "find_by_localized_slug falls back to base slug" do
    category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    assert_equal category, Category.find_by_localized_slug("actualites", :en)
  end

  test "find_by_localized_slug returns nil for unknown slug" do
    Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    assert_nil Category.find_by_localized_slug("unknown", :en)
  end
end
