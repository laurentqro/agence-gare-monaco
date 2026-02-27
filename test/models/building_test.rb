require "test_helper"

class BuildingTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "Monte-Carlo", city: "Monaco")
  end

  test "valid building with all attributes" do
    building = Building.new(
      name: "Le Montaigne",
      name_alt: "Montaigne",
      address: "1 Avenue de Monte-Carlo",
      district: @district,
      city: "Monaco",
      immotoolbox_id: 1
    )
    assert building.valid?
  end

  test "requires name" do
    building = Building.new(city: "Monaco")
    assert_not building.valid?
    assert_includes building.errors[:name], "can't be blank"
  end

  test "belongs to district optionally" do
    building = Building.new(name: "Le Montaigne", city: "Monaco")
    assert building.valid?
  end

  test "immotoolbox_id is unique when present" do
    Building.create!(name: "Le Montaigne", city: "Monaco", immotoolbox_id: 99)
    duplicate = Building.new(name: "Another", city: "Monaco", immotoolbox_id: 99)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:immotoolbox_id], "has already been taken"
  end

  test "has many properties" do
    assert_equal :has_many, Building.reflect_on_association(:properties).macro
  end

  test "belongs to district" do
    assert_equal :belongs_to, Building.reflect_on_association(:district).macro
  end
end
