require "test_helper"

class BrowserSupportTest < ActionDispatch::IntegrationTest
  SAFARI_17_1 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Safari/605.1.15"
  SAFARI_13_MOBILE = "Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1"

  test "homepage is served to Safari 17.1 on macOS" do
    get "/", headers: { "User-Agent" => SAFARI_17_1 }
    assert_response :success
  end

  test "homepage is served to older mobile Safari" do
    get "/", headers: { "User-Agent" => SAFARI_13_MOBILE }
    assert_response :success
  end
end
