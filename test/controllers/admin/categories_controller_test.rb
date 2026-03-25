require "test_helper"

class Admin::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get admin_categories_url
    assert_redirected_to new_session_url
  end

  # INDEX
  test "GET index lists all categories" do
    Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Category.create!(name: { "fr" => "Quartiers" }, slug: "quartiers")
    get admin_categories_url
    assert_response :success
    assert_select "h1", /Catégories/
    assert_select "table tbody tr", 2
  end

  test "GET index shows article count per category" do
    cat = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Article.create!(title: { "fr" => "A1" }, body: { "fr" => "C" }, slug: "a1", category: cat)
    Article.create!(title: { "fr" => "A2" }, body: { "fr" => "C" }, slug: "a2", category: cat)
    get admin_categories_url
    assert_response :success
    assert_select "td", /2/
  end

  # NEW
  test "GET new renders category form" do
    get new_admin_category_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='category[name][fr]']"
  end

  # CREATE
  test "POST create creates category and redirects" do
    assert_difference "Category.count", 1 do
      post admin_categories_url, params: {
        category: { name: { "fr" => "Fiscalité" }, slug: "fiscalite" }
      }
    end
    assert_redirected_to admin_categories_url
    assert_equal "Fiscalité", Category.last.name_for(:fr)
  end

  test "POST create auto-generates slug when blank" do
    post admin_categories_url, params: {
      category: { name: { "fr" => "Sécurité & Santé" }, slug: "" }
    }
    assert_equal "securite-sante", Category.last.slug
  end

  test "POST create with invalid data re-renders form" do
    assert_no_difference "Category.count" do
      post admin_categories_url, params: {
        category: { name: { "fr" => "" }, slug: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  # EDIT
  test "GET edit renders form with existing data" do
    cat = Category.create!(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    get edit_admin_category_url(cat)
    assert_response :success
    assert_select "input[name='category[name][fr]']" do |inputs|
      assert_equal "Actualités", inputs.first["value"]
    end
  end

  # UPDATE
  test "PATCH update updates category and redirects" do
    cat = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    patch admin_category_url(cat), params: {
      category: { name: { "fr" => "News" } }
    }
    assert_redirected_to admin_categories_url
    cat.reload
    assert_equal "News", cat.name_for(:fr)
  end

  test "PATCH update with invalid data re-renders form" do
    cat = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    Category.create!(name: { "fr" => "Other" }, slug: "other")
    patch admin_category_url(cat), params: {
      category: { slug: "other" }
    }
    assert_response :unprocessable_entity
  end

  # DESTROY
  test "DELETE destroy deletes category and redirects" do
    cat = Category.create!(name: { "fr" => "To delete" }, slug: "to-delete")
    assert_difference "Category.count", -1 do
      delete admin_category_url(cat)
    end
    assert_redirected_to admin_categories_url
  end

  test "DELETE destroy also deletes associated articles" do
    cat = Category.create!(name: { "fr" => "To delete" }, slug: "to-delete")
    Article.create!(title: { "fr" => "Art" }, body: { "fr" => "C" }, slug: "art", category: cat)
    assert_difference [ "Category.count", "Article.count" ], -1 do
      delete admin_category_url(cat)
    end
  end
end
