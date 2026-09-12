require "test_helper"

class PropertyShareMessageTest < ActionView::TestCase
  include ApplicationHelper

  setup do
    @property = Property.create!(
      reference: "MC-500",
      title: { "fr" => "Penthouse vue mer", "en" => "Sea view penthouse" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    @url = "https://agencegaremonaco.com/en/properties/#{@property.id}-sea-view-penthouse"
  end

  test "property_share_message pairs the localized title with the reference and the URL" do
    I18n.with_locale(:en) do
      message = property_share_message(@property, @url)

      assert_includes message, "Sea view penthouse"
      assert_includes message, "MC-500"
      assert_includes message, @url
    end
  end

  test "property_share_message uses the current locale's title and reference wording" do
    I18n.with_locale(:fr) do
      message = property_share_message(@property, @url)

      assert_includes message, "Penthouse vue mer"
      assert_includes message, "Référence MC-500"
    end
  end

  test "property_share_subject names the property and the agency" do
    I18n.with_locale(:en) do
      subject = property_share_subject(@property)

      assert_includes subject, "Sea view penthouse"
      assert_includes subject, "Agence Immobilière de la Gare"
    end
  end
end
