require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category" do
    category = Category.new(name: "Actualités", slug: "actualites")
    assert category.valid?
  end

  test "requires name" do
    category = Category.new(slug: "actualites")
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "requires slug" do
    category = Category.new(name: "Actualités")
    assert_not category.valid?
    assert_includes category.errors[:slug], "can't be blank"
  end

  test "slug is unique" do
    Category.create!(name: "Actualités", slug: "actualites")
    duplicate = Category.new(name: "News", slug: "actualites")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
  end

  test "has many articles" do
    assert_equal :has_many, Category.reflect_on_association(:articles).macro
  end
end
