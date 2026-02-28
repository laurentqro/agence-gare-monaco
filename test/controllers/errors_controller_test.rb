require "test_helper"

class ErrorsControllerTest < ActionDispatch::IntegrationTest
  # === 404 Page ===

  test "404 page renders with agency branding" do
    get "/404"
    assert_response :not_found
    assert_select "h1", /404/
  end

  test "404 page includes navigation back to homepage" do
    get "/404"
    assert_response :not_found
    assert_select "a[href='/fr']"
  end

  test "404 page includes agency logo" do
    get "/404"
    assert_response :not_found
    assert_select "img[alt='Agence Immobilière de la Gare']"
  end

  test "404 page displays translated error message" do
    get "/404"
    assert_response :not_found
    assert_select "[data-testid='error-message']"
  end

  test "404 page includes browse suggestion links" do
    get "/404"
    assert_response :not_found
    assert_select "a[href='/fr/ventes/monaco']"
  end

  test "404 page includes noindex meta tag" do
    get "/404"
    assert_response :not_found
    assert_select "meta[name='robots'][content='noindex']"
  end

  test "404 page uses agency-branded layout with Montserrat font" do
    get "/404"
    assert_response :not_found
    assert_select "body[class*='Montserrat']"
  end

  # === 422 Page ===

  test "422 page renders with agency branding" do
    get "/422"
    assert_response :unprocessable_entity
    assert_select "h1", /422/
  end

  # === 500 Page ===

  test "500 page renders with agency branding" do
    get "/500"
    assert_response :internal_server_error
    assert_select "h1", /500/
  end

  test "500 page includes link back to homepage" do
    get "/500"
    assert_response :internal_server_error
    assert_select "a[href='/fr']"
  end

  test "500 page includes noindex meta tag" do
    get "/500"
    assert_response :internal_server_error
    assert_select "meta[name='robots'][content='noindex']"
  end

  test "500 page includes agency logo" do
    get "/500"
    assert_response :internal_server_error
    assert_select "img[alt='Agence Immobilière de la Gare']"
  end
end
