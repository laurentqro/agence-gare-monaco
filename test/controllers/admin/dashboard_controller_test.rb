require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects unauthenticated users to login" do
    get admin_root_url
    assert_redirected_to new_session_url
  end

  test "allows authenticated users to access admin" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url
    assert_response :success
  end
end
