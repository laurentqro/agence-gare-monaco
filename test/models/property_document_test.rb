require "test_helper"

class PropertyDocumentTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
  end

  test "valid property document" do
    doc = PropertyDocument.new(property: @property, label: "Floor Plan")
    assert doc.valid?
  end

  test "requires property" do
    doc = PropertyDocument.new(label: "Floor Plan")
    assert_not doc.valid?
    assert_includes doc.errors[:property], "must exist"
  end

  test "belongs to property" do
    assert_equal :belongs_to, PropertyDocument.reflect_on_association(:property).macro
  end
end
