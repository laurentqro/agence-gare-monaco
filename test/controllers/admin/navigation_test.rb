require "test_helper"

class Admin::NavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  test "admin dashboard shows navigation links" do
    get admin_root_url
    assert_response :success
    assert_select "a[href='#{admin_root_path}']", /Dashboard/
    assert_select "a[href='#{admin_articles_path}']", /Articles/
    assert_select "a[href='#{admin_categories_path}']", /Categories/
  end

  test "admin articles index shows navigation links" do
    get admin_articles_url
    assert_response :success
    assert_select "a[href='#{admin_root_path}']", /Dashboard/
    assert_select "a[href='#{admin_articles_path}']", /Articles/
    assert_select "a[href='#{admin_categories_path}']", /Categories/
  end

  test "admin layout shows logout link" do
    get admin_root_url
    assert_response :success
    assert_select "a", /Log out|Logout|Sign out/i
  end

  test "admin layout shows current user email" do
    get admin_root_url
    assert_response :success
    assert_includes response.body, "adrien@agencegaremonaco.com"
  end
end
