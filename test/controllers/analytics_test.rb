require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  test "Plausible script tag is present on homepage" do
    get "/en"
    assert_response :success
    assert_select "script[data-domain='agencegaremonaco.com']"
  end

  test "Plausible script tag is present on property listing page" do
    property = Property.create!(
      reference: "PLAUS-001", title: { "en" => "Test" }, transaction_type: "sale",
      property_type: "apartment", country: "MC", city: "Monaco", published: true, off_market: false
    )
    get "/en/sales"
    assert_response :success
    assert_select "script[data-domain='agencegaremonaco.com']"
  end

  test "Plausible script tag is NOT present on admin pages" do
    get new_session_path
    assert_response :success
    assert_select "script[data-domain='agencegaremonaco.com']", count: 0
  end

  test "Plausible script uses defer attribute" do
    get "/en"
    assert_response :success
    assert_select "script[defer][data-domain='agencegaremonaco.com']"
  end
end
