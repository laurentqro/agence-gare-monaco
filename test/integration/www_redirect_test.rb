require "test_helper"

# www.agencegaremonaco.com must 301-redirect to the apex so there is a single
# canonical host. kamal-proxy serves both hosts identically, so the redirect is
# enforced at the app layer (TrailingSlashRedirector middleware). See Google
# "Duplicate without user-selected canonical" — Google was picking www on its own.
class WwwRedirectTest < ActionDispatch::IntegrationTest
  test "redirects www homepage to apex with 301" do
    get "https://www.agencegaremonaco.com/"
    assert_response :moved_permanently
    assert_equal "https://agencegaremonaco.com/", response.location
  end

  test "preserves the path when redirecting www to apex" do
    get "https://www.agencegaremonaco.com/ventes/monaco"
    assert_response :moved_permanently
    assert_equal "https://agencegaremonaco.com/ventes/monaco", response.location
  end

  test "preserves the query string when redirecting www to apex" do
    get "https://www.agencegaremonaco.com/ventes?type=apartment"
    assert_response :moved_permanently
    assert_equal "https://agencegaremonaco.com/ventes?type=apartment", response.location
  end

  test "redirects www over http to https apex" do
    get "http://www.agencegaremonaco.com/"
    assert_response :moved_permanently
    assert_equal "https://agencegaremonaco.com/", response.location
  end

  test "does not redirect the apex host" do
    get "https://agencegaremonaco.com/"
    assert_response :success
  end
end
