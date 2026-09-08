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
    assert_select "a[href='/']"
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
    assert_select "a[href='/ventes']"
    assert_select "a[href='/locations']"
    assert_select "a[href='/contact']"
  end

  test "404 recovery links are built from the translated route segments" do
    get "/404"
    assert_select "[data-testid='where-to-look-next'] a[href='/en/sales']"
    assert_select "[data-testid='where-to-look-next'] a[href='/en/about']"
    assert_select "[data-testid='where-to-look-next'] a[href='/articles']"
  end

  test "404 page points agents at the sitemap and llms.txt" do
    get "/404"
    assert_response :not_found
    assert_select "[data-testid='where-to-look-next'] a[href='/sitemap.xml']"
    assert_select "[data-testid='where-to-look-next'] a[href='/llms.txt']"
  end

  test "404 page is served as markdown to agents that ask for it" do
    get "/404", headers: { "Accept" => "text/markdown" }
    assert_response :not_found
    assert_equal "text/markdown; charset=utf-8", response.content_type
    assert_includes response.body, "# 404"
    assert_includes response.body, "https://agencegaremonaco.com/sitemap.xml"
    assert_includes response.body, "https://agencegaremonaco.com/llms.txt"
    assert_no_match(/<(div|a|html)\b/i, response.body)
  end

  test "nonexistent paths return a real 404 with the agent-friendly body" do
    without_detailed_exceptions do
      get "/some-path-that-does-not-exist"
      assert_response :not_found
      assert_select "[data-testid='where-to-look-next'] a[href='/sitemap.xml']"

      get "/some-path-that-does-not-exist", headers: { "Accept" => "text/markdown" }
      assert_response :not_found
      assert_equal "text/markdown; charset=utf-8", response.content_type
      assert_includes response.body, "https://agencegaremonaco.com/llms.txt"
    end
  end

  test "404 page includes noindex meta tag" do
    get "/404"
    assert_response :not_found
    assert_select "meta[name='robots'][content='noindex']"
  end

  test "404 page uses agency-branded layout with Domine font" do
    get "/404"
    assert_response :not_found
    assert_select "body[class*='Domine']"
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
    assert_select "a[href='/']"
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

  private

  def without_detailed_exceptions
    env_config = Rails.application.env_config
    previous = env_config["action_dispatch.show_detailed_exceptions"]
    env_config["action_dispatch.show_detailed_exceptions"] = false
    yield
  ensure
    env_config["action_dispatch.show_detailed_exceptions"] = previous
  end
end
