require "test_helper"

class AnalyticsTest < ActionDispatch::IntegrationTest
  PLAUSIBLE_SRC = "plausible.io/js/pa-JTo1asj68MUtTtbaCOJVm.js".freeze

  test "Plausible script tag is present on homepage" do
    get "/en"
    assert_response :success
    assert_includes response.body, PLAUSIBLE_SRC
  end

  test "Plausible script tag is present on property listing page" do
    property = Property.create!(
      reference: "PLAUS-001", title: { "en" => "Test" }, transaction_type: "sale",
      property_type: "apartment", country: "MC", city: "Monaco", published: true, off_market: false
    )
    get "/en/sales"
    assert_response :success
    assert_includes response.body, PLAUSIBLE_SRC
  end

  test "Plausible script tag is NOT present on admin pages" do
    get new_session_path
    assert_response :success
    assert_not_includes response.body, PLAUSIBLE_SRC
  end

  test "Plausible loader bootstraps via plausible.init" do
    get "/en"
    assert_response :success
    assert_includes response.body, "plausible.init()"
  end
end
