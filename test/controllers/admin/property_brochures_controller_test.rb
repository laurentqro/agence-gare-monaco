require "test_helper"

class Admin::PropertyBrochuresControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }

    @property = Property.create!(
      reference: "MC-BRO-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      published: true
    )
  end

  # Authentication
  test "redirects unauthenticated users to login for new" do
    delete session_url
    get new_admin_property_brochure_url(@property)
    assert_redirected_to new_session_url
  end

  test "redirects unauthenticated users to login for create" do
    delete session_url
    post admin_property_brochure_url(@property), params: { locale: "fr" }
    assert_redirected_to new_session_url
  end

  # NEW (options form)
  test "GET new renders brochure options form" do
    get new_admin_property_brochure_url(@property)
    assert_response :success
    assert_select "h1", /Brochure PDF/
  end

  test "GET new shows property summary" do
    get new_admin_property_brochure_url(@property)
    assert_response :success
    assert_select "td", /MC-BRO-001/
  end

  test "GET new shows locale selector with 9 options" do
    get new_admin_property_brochure_url(@property)
    assert_response :success
    assert_select "select[name='locale'] option", 9
  end

  test "GET new shows logo checkbox" do
    get new_admin_property_brochure_url(@property)
    assert_response :success
    assert_select "input[type='checkbox'][name='include_logo']"
  end

  # CREATE (generate PDF)
  test "POST create returns PDF with correct content type" do
    post admin_property_brochure_url(@property), params: { locale: "fr" }
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "POST create returns PDF with attachment disposition" do
    post admin_property_brochure_url(@property), params: { locale: "fr" }
    assert_response :success
    assert_match /attachment/, response.headers["Content-Disposition"]
    assert_match /MC-BRO-001/, response.headers["Content-Disposition"]
  end

  test "POST create with different locale generates PDF" do
    post admin_property_brochure_url(@property), params: { locale: "en" }
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "POST create with include_logo=0 generates PDF" do
    post admin_property_brochure_url(@property), params: { locale: "fr", include_logo: "0" }
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "POST create with include_logo=1 generates PDF" do
    post admin_property_brochure_url(@property), params: { locale: "fr", include_logo: "1" }
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "POST create defaults to French locale" do
    post admin_property_brochure_url(@property)
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end
end
