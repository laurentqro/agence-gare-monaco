require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  test "available locales are configured" do
    assert_equal %i[fr en it de sv no da fi ru], I18n.available_locales
  end

  test "default locale is French" do
    assert_equal :fr, I18n.default_locale
  end

  test "bare root serves French homepage directly" do
    get "/"
    assert_response :success
    assert_match "Monaco depuis 1942", response.body
  end

  test "locale prefix renders content in correct language" do
    get "/"
    assert_response :success
    assert_match "Monaco depuis 1942", response.body

    get "/en"
    assert_response :success
    assert_match "Real Estate in Monaco since 1942", response.body

    get "/de"
    assert_response :success
    assert_match "Immobilien in Monaco seit 1942", response.body
  end

  test "invalid locale returns 404" do
    get "/xx"
    assert_response :not_found
  end

  test "each locale file has site_name translation" do
    I18n.available_locales.each do |locale|
      assert I18n.exists?(:site_name, locale), "Missing site_name for locale #{locale}"
    end
  end

  test "each locale file has nav translations" do
    I18n.available_locales.each do |locale|
      assert I18n.exists?("nav.buy", locale), "Missing nav.buy for locale #{locale}"
      assert I18n.exists?("nav.rent", locale), "Missing nav.rent for locale #{locale}"
      assert I18n.exists?("nav.offmarket", locale), "Missing nav.offmarket for locale #{locale}"
      assert I18n.exists?("nav.sell", locale), "Missing nav.sell for locale #{locale}"
      assert I18n.exists?("nav.management", locale), "Missing nav.management for locale #{locale}"
      assert I18n.exists?("nav.articles", locale), "Missing nav.articles for locale #{locale}"
      assert I18n.exists?("nav.contact", locale), "Missing nav.contact for locale #{locale}"
    end
  end

  test "each locale file has homepage translations" do
    I18n.available_locales.each do |locale|
      assert I18n.exists?("homepage.hero_title", locale), "Missing homepage.hero_title for locale #{locale}"
      assert I18n.exists?("homepage.hero_subtitle", locale), "Missing homepage.hero_subtitle for locale #{locale}"
    end
  end

  test "each locale has route segment translations" do
    I18n.available_locales.each do |locale|
      assert I18n.exists?("routes.sales", locale), "Missing routes.sales for locale #{locale}"
      assert I18n.exists?("routes.rentals", locale), "Missing routes.rentals for locale #{locale}"
      assert I18n.exists?("routes.properties", locale), "Missing routes.properties for locale #{locale}"
      assert I18n.exists?("routes.articles", locale), "Missing routes.articles for locale #{locale}"
      assert I18n.exists?("routes.contact", locale), "Missing routes.contact for locale #{locale}"
      assert I18n.exists?("routes.privacy", locale), "Missing routes.privacy for locale #{locale}"
      assert I18n.exists?("routes.france", locale), "Missing routes.france for locale #{locale}"
    end
  end

  test "French route translations are correct" do
    assert_equal "ventes", I18n.t("routes.sales", locale: :fr)
    assert_equal "locations", I18n.t("routes.rentals", locale: :fr)
    assert_equal "biens", I18n.t("routes.properties", locale: :fr)
    assert_equal "articles", I18n.t("routes.articles", locale: :fr)
    assert_equal "contact", I18n.t("routes.contact", locale: :fr)
    assert_equal "confidentialite", I18n.t("routes.privacy", locale: :fr)
    assert_equal "france", I18n.t("routes.france", locale: :fr)
  end

  test "English route translations are correct" do
    assert_equal "sales", I18n.t("routes.sales", locale: :en)
    assert_equal "rentals", I18n.t("routes.rentals", locale: :en)
    assert_equal "properties", I18n.t("routes.properties", locale: :en)
    assert_equal "articles", I18n.t("routes.articles", locale: :en)
    assert_equal "contact", I18n.t("routes.contact", locale: :en)
    assert_equal "privacy", I18n.t("routes.privacy", locale: :en)
    assert_equal "france", I18n.t("routes.france", locale: :en)
  end

  test "German route translations are correct" do
    assert_equal "verkauf", I18n.t("routes.sales", locale: :de)
    assert_equal "vermietung", I18n.t("routes.rentals", locale: :de)
    assert_equal "immobilien", I18n.t("routes.properties", locale: :de)
    assert_equal "artikel", I18n.t("routes.articles", locale: :de)
    assert_equal "kontakt", I18n.t("routes.contact", locale: :de)
    assert_equal "datenschutz", I18n.t("routes.privacy", locale: :de)
    assert_equal "frankreich", I18n.t("routes.france", locale: :de)
  end

  test "Italian route translations are correct" do
    assert_equal "vendite", I18n.t("routes.sales", locale: :it)
    assert_equal "affitti", I18n.t("routes.rentals", locale: :it)
    assert_equal "immobili", I18n.t("routes.properties", locale: :it)
    assert_equal "articoli", I18n.t("routes.articles", locale: :it)
    assert_equal "contatto", I18n.t("routes.contact", locale: :it)
    assert_equal "privacy", I18n.t("routes.privacy", locale: :it)
    assert_equal "francia", I18n.t("routes.france", locale: :it)
  end

  test "admin routes are not affected by locale" do
    user = User.create!(email_address: "admin@test.com", password: "password123")
    post session_url, params: { email_address: "admin@test.com", password: "password123" }
    get admin_root_url
    assert_response :success
  end

  test "session routes are not affected by locale" do
    get new_session_url
    assert_response :success
  end

  test "locale does not leak between requests" do
    get "/de"
    assert_response :success
    assert_match "Immobilien in Monaco seit 1942", response.body

    get "/"
    assert_response :success
    assert_match "Monaco depuis 1942", response.body
    assert_no_match(/Immobilien/, response.body)
  end

  test "all nine locales are routable" do
    get "/"
    assert_response :success, "Expected 200 for / (fr) but got #{response.status}"

    %w[en it de sv no da fi ru].each do |locale|
      get "/#{locale}"
      assert_response :success, "Expected 200 for /#{locale} but got #{response.status}"
    end
  end
end
