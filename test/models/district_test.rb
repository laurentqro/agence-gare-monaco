require "test_helper"

class DistrictTest < ActiveSupport::TestCase
  test "valid district with all attributes" do
    district = District.new(
      name: "Carré d'Or",
      city: "Monaco",
      latitude: 43.7384,
      longitude: 7.4246,
      immotoolbox_id: 1
    )
    assert district.valid?
  end

  test "requires name" do
    district = District.new(city: "Monaco")
    assert_not district.valid?
    assert_includes district.errors[:name], "can't be blank"
  end

  test "requires city" do
    district = District.new(name: "Carré d'Or")
    assert_not district.valid?
    assert_includes district.errors[:city], "can't be blank"
  end

  test "immotoolbox_id is unique when present" do
    District.create!(name: "Carré d'Or", city: "Monaco", immotoolbox_id: 42)
    duplicate = District.new(name: "Another", city: "Monaco", immotoolbox_id: 42)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:immotoolbox_id], "has already been taken"
  end

  test "has many buildings" do
    assert_equal :has_many, District.reflect_on_association(:buildings).macro
  end

  test "has many properties" do
    assert_equal :has_many, District.reflect_on_association(:properties).macro
  end

  test "generates slug from name" do
    district = District.create!(name: "La Rousse - Saint Roman", city: "Monaco")
    assert_equal "la-rousse-saint-roman", district.slug
  end
end
