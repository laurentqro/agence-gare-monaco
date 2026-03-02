require "test_helper"

class Admin::FrenchLocaleTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
  end

  test "login page renders in French" do
    get new_session_url
    assert_response :success
    assert_select "label", text: /Email/
    assert_select "label", text: /Mot de passe/
    assert_select "input[type='submit'][value='Se connecter']"
  end

  test "login error message is in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "wrong" }
    assert_redirected_to new_session_url
    follow_redirect!
    assert_select "p", /Adresse email ou mot de passe incorrect/
  end

  test "admin dashboard renders in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url
    assert_response :success
    assert_select "h1", /Tableau de bord/
    assert_select "p", /Bienvenue/
  end

  test "admin sidebar renders in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url
    assert_response :success
    assert_select "a", text: "Tableau de bord"
    assert_select "a", text: /Biens/
    assert_select "a", text: "Articles"
    assert_select "a", text: /Cat/
    assert_select "a", text: "Contacts"
    assert_select "a", text: /connexion/i
  end

  test "admin renders in French even when I18n.locale is not French" do
    I18n.locale = :en
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_root_url
    assert_response :success
    assert_select "h1", /Tableau de bord/
    assert_select "a", text: /connexion/i
  end

  test "articles index renders in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    category = Category.create!(name: "Test", slug: "test")
    Article.create!(title: { "fr" => "Mon article" }, body: { "fr" => "Contenu" }, slug: "mon-article", category: category, published: true)
    get admin_articles_url
    assert_response :success
    assert_select "th", /Titre/
    assert_select "th", /Statut/
    assert_select "span", /Publié/
  end

  test "properties index renders in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    Property.create!(
      reference: "MC-001", title: { "fr" => "Studio" }, description: { "fr" => "Desc" },
      transaction_type: "sale", property_type: "studio", country: "MC", city: "Monaco", published: true
    )
    get admin_properties_url
    assert_response :success
    assert_select "th", /Référence/
    assert_select "th", /Prix/
    assert_select "span", /Publié/
  end

  test "contacts index renders in French" do
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    get admin_contacts_url
    assert_response :success
    assert_select "th", /Nom/
    assert_select "th", /Prénom/
  end
end
