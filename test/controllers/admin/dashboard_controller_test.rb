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

  test "dashboard shows quick links section" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "h2", text: "Actions rapides"
  end

  test "dashboard has link to create a new article" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "a[href=?]", new_admin_article_path, text: "Rédiger un article"
  end

  test "dashboard has link to create a new off-market property" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "a[href=?]", new_admin_property_path, text: "Ajouter un bien off market"
  end

  test "dashboard has link to create a new contact" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "a[href=?]", new_admin_contact_path, text: "Ajouter un contact"
  end

  test "dashboard has link to view all properties" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "a[href=?]", admin_properties_path, text: "Voir tous les biens"
  end

  test "dashboard has link to view all contacts" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url

    assert_select "a[href=?]", admin_contacts_path, text: "Voir tous les contacts"
  end
end
