require "test_helper"

class Admin::NavigationTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  test "admin dashboard shows navigation links" do
    get admin_root_url
    assert_response :success
    assert_select "a[href='#{admin_root_path}']", /Tableau de bord/
    assert_select "a[href='#{admin_articles_path}']", /Articles/
    assert_select "a[href='#{admin_categories_path}']", /Catégories/
  end

  test "admin articles index shows navigation links" do
    get admin_articles_url
    assert_response :success
    assert_select "a[href='#{admin_root_path}']", /Tableau de bord/
    assert_select "a[href='#{admin_articles_path}']", /Articles/
    assert_select "a[href='#{admin_categories_path}']", /Catégories/
  end

  test "admin sidebar logo links to the public site" do
    get admin_root_url
    assert_response :success
    assert_select "a[href='#{fr_root_path}'] img[src*='logo-monogram']"
  end

  test "admin layout shows a view-site icon link in a top bar above the content" do
    get admin_root_url
    assert_response :success
    assert_select "header a[href='#{fr_root_path}'][aria-label='Voir le site'] svg"
    # Must not float over the content where it can cover page action buttons
    assert_select "a[aria-label='Voir le site'][class*='fixed']", count: 0
  end

  test "admin layout shows logout link" do
    get admin_root_url
    assert_response :success
    assert_select "a", /Déconnexion/
  end

  test "admin layout shows current user email" do
    get admin_root_url
    assert_response :success
    assert_includes response.body, "adrien@agencegaremonaco.com"
  end
end
