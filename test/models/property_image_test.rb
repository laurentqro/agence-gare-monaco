require "test_helper"

class PropertyImageTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
  end

  test "valid property image" do
    image = PropertyImage.new(
      property: @property,
      remote_url: "https://clientapi.immotoolbox.com/media/cache/resolve/large/uploads/images/1/photo.jpg",
      thumb_url: "https://clientapi.immotoolbox.com/media/cache/resolve/thumb/uploads/images/1/photo.jpg",
      small_url: "https://clientapi.immotoolbox.com/media/cache/resolve/small/uploads/images/1/photo.jpg",
      medium_url: "https://clientapi.immotoolbox.com/media/cache/resolve/medium/uploads/images/1/photo.jpg",
      large_url: "https://clientapi.immotoolbox.com/media/cache/resolve/large/uploads/images/1/photo.jpg",
      position: 1,
      is_plan: false,
      immotoolbox_id: 1
    )
    assert image.valid?
  end

  test "requires property" do
    image = PropertyImage.new(remote_url: "https://example.com/photo.jpg")
    assert_not image.valid?
    assert_includes image.errors[:property], "must exist"
  end

  test "requires remote_url" do
    image = PropertyImage.new(property: @property)
    assert_not image.valid?
    assert_includes image.errors[:remote_url], "can't be blank"
  end

  test "belongs to property" do
    assert_equal :belongs_to, PropertyImage.reflect_on_association(:property).macro
  end

  test "default position is 0" do
    image = PropertyImage.create!(property: @property, remote_url: "https://example.com/photo.jpg")
    assert_equal 0, image.position
  end

  test "default is_plan is false" do
    image = PropertyImage.create!(property: @property, remote_url: "https://example.com/photo.jpg")
    assert_equal false, image.is_plan
  end

  test "ordered by position" do
    PropertyImage.create!(property: @property, remote_url: "https://example.com/b.jpg", position: 2)
    PropertyImage.create!(property: @property, remote_url: "https://example.com/a.jpg", position: 1)
    assert_equal ["https://example.com/a.jpg", "https://example.com/b.jpg"],
                 @property.property_images.ordered.map(&:remote_url)
  end
end
