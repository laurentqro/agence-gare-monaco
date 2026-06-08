require "test_helper"

class AdminPropertyTypeHelperTest < ActionView::TestCase
  include ApplicationHelper

  def label(transaction_type:, property_type:)
    property = Property.new(transaction_type: transaction_type, property_type: property_type)
    I18n.with_locale(:fr) { admin_property_type_label(property) }
  end

  test "translates transaction and property type to French" do
    assert_equal "Vente · Appartement", label(transaction_type: "sale", property_type: "apartment")
    assert_equal "Location · Studio", label(transaction_type: "rental", property_type: "studio")
  end

  test "normalizes inconsistent casing and language in DB values" do
    assert_equal "Vente · Appartement", label(transaction_type: "sale", property_type: "Appartement")
    assert_equal "Vente · Cave", label(transaction_type: "sale", property_type: "cave")
    assert_equal "Vente · Box", label(transaction_type: "sale", property_type: "box")
    assert_equal "Vente · Autre produit", label(transaction_type: "sale", property_type: "autre produit")
    assert_equal "Vente · Cession de droit au bail", label(transaction_type: "sale", property_type: "cessions de droit au bail")
  end

  test "falls back to capitalized raw value for unknown property types" do
    assert_equal "Vente · Loft atypique", label(transaction_type: "sale", property_type: "loft atypique")
  end
end
