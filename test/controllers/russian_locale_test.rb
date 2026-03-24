require "test_helper"

class RussianLocaleTest < ActionDispatch::IntegrationTest
  # === Configuration ===

  test "Russian is included in available locales" do
    assert_includes I18n.available_locales, :ru
  end

  test "Russian locale has site_name translation" do
    assert I18n.exists?(:site_name, :ru), "Missing site_name for ru"
  end

  test "Russian locale has all nav translations" do
    %w[buy rent offmarket sell management articles contact privacy faq].each do |key|
      assert I18n.exists?("nav.#{key}", :ru), "Missing nav.#{key} for ru"
    end
  end

  test "Russian locale has homepage translations" do
    %w[hero_title hero_subtitle about_title team_title contact_title].each do |key|
      assert I18n.exists?("homepage.#{key}", :ru), "Missing homepage.#{key} for ru"
    end
  end

  test "Russian locale has route segment translations" do
    %w[sales rentals properties articles contact privacy france offmarket gestion vendre faq team].each do |key|
      assert I18n.exists?("routes.#{key}", :ru), "Missing routes.#{key} for ru"
    end
  end

  test "Russian route translations use transliterated Latin" do
    assert_equal "prodazha", I18n.t("routes.sales", locale: :ru)
    assert_equal "arenda", I18n.t("routes.rentals", locale: :ru)
    assert_equal "obekty", I18n.t("routes.properties", locale: :ru)
    assert_equal "stati", I18n.t("routes.articles", locale: :ru)
    assert_equal "kontakt", I18n.t("routes.contact", locale: :ru)
    assert_equal "konfidentsialnost", I18n.t("routes.privacy", locale: :ru)
    assert_equal "frantsiya", I18n.t("routes.france", locale: :ru)
    assert_equal "off-market", I18n.t("routes.offmarket", locale: :ru)
    assert_equal "upravlenie", I18n.t("routes.gestion", locale: :ru)
    assert_equal "prodat", I18n.t("routes.vendre", locale: :ru)
    assert_equal "faq", I18n.t("routes.faq", locale: :ru)
    assert_equal "komanda", I18n.t("routes.team", locale: :ru)
  end

  # === Routes ===

  test "RU homepage route works" do
    get "/ru"
    assert_response :success
  end

  test "RU sales listing route" do
    get "/ru/prodazha"
    assert_response :success
  end

  test "RU rentals listing route" do
    get "/ru/arenda"
    assert_response :success
  end

  test "RU articles listing route" do
    get "/ru/stati"
    assert_response :success
  end

  test "RU contact route" do
    get "/ru/kontakt"
    assert_response :success
  end

  test "RU privacy route" do
    get "/ru/konfidentsialnost"
    assert_response :success
  end

  test "RU property detail route" do
    property = Property.create!(
      reference: "REF-RU",
      title: { "ru" => "Студия в Монако" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    get "/ru/obekty/#{property.id}-studiya-v-monako"
    assert_response :success
  end

  # === Content ===

  test "RU homepage renders Russian content" do
    get "/ru"
    assert_response :success
    assert_match "Недвижимость в Монако с 1942 года", response.body
  end

  test "html lang attribute is ru for Russian locale" do
    get "/ru"
    assert_match '<html lang="ru">', response.body
  end

  # === SEO ===

  test "Russian locale has all SEO translations" do
    %w[homepage_title homepage_description articles_description contact_description privacy_description].each do |key|
      assert I18n.exists?("seo.#{key}", :ru), "Missing seo.#{key} for ru"
    end
  end

  test "Russian locale has property detail translations" do
    %w[reference building district type floor rooms bedrooms bathrooms].each do |key|
      assert I18n.exists?("property_detail.#{key}", :ru), "Missing property_detail.#{key} for ru"
    end
  end

  test "Russian locale has listings translations" do
    %w[sales rentals no_properties filter_type filter_district].each do |key|
      assert I18n.exists?("listings.#{key}", :ru), "Missing listings.#{key} for ru"
    end
  end

  test "Russian locale has contact_form translations" do
    %w[title name email subject message send].each do |key|
      assert I18n.exists?("contact_form.#{key}", :ru), "Missing contact_form.#{key} for ru"
    end
  end

  test "Russian locale has gestion page translations" do
    assert I18n.exists?("gestion.title", :ru), "Missing gestion.title for ru"
  end

  test "Russian locale has vendre page translations" do
    assert I18n.exists?("vendre.title", :ru), "Missing vendre.title for ru"
  end

  test "Russian locale has pdf_brochure translations" do
    %w[price_on_request disclaimer agency_name].each do |key|
      assert I18n.exists?("pdf_brochure.#{key}", :ru), "Missing pdf_brochure.#{key} for ru"
    end
  end

  # === Currency ===

  test "Russian locale falls back to EUR for currency" do
    assert_equal "EUR", ExchangeRate.locale_currency(:ru)
  end
end
