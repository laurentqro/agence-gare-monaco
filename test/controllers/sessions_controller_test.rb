require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
  end

  test "GET /session/new renders login form" do
    get new_session_url
    assert_response :success
  end

  test "POST /session with valid credentials creates session and redirects" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    assert_redirected_to admin_root_url
  end

  test "POST /session with invalid credentials re-renders login" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "wrong" }
    assert_redirected_to new_session_url
  end

  test "DELETE /session destroys session and redirects to login" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    delete session_url
    assert_redirected_to new_session_url
  end
end
