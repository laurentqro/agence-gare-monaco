require "test_helper"

class PrivacyPageTest < ActionDispatch::IntegrationTest
  # === FR page structure ===

  test "FR privacy page renders at /confidentialite" do
    get "/confidentialite"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :fr)}/
    assert_select "[data-testid='privacy-content']"
  end

  test "FR privacy page links to Monaco law" do
    get "/confidentialite"
    assert_select "[data-testid='privacy-content'] a[href='https://legimonaco.mc/tnc/loi/2024/12-03-1.565']", text: /Loi n° 1\.565 du 3 décembre 2024/
  end

  test "FR privacy page includes data controller section" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.controller_title", locale: :fr)}/
    assert_select "[data-testid='privacy-content']", text: /Agence de la Gare/
    assert_select "[data-testid='privacy-content']", text: /3, rue Langlé/i
    assert_select "[data-testid='privacy-content']", text: /info@agencegaremonaco.com/
  end

  test "FR privacy page includes contact form processing activity" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.contact_form_title", locale: :fr)}/
  end

  test "FR privacy page includes property inquiry processing activity" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.property_inquiry_title", locale: :fr)}/
  end

  test "FR privacy page includes analytics processing activity" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.analytics_title", locale: :fr)}/
    assert_select "[data-testid='privacy-content']", text: /Plausible/
  end

  test "FR privacy page lists all 8 Monaco data subject rights" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.rights_title", locale: :fr)}/
    # 8 rights under Loi n° 1.565
    assert_select "[data-testid='privacy-content']", text: /information/i
    assert_select "[data-testid='privacy-content']", text: /accès/i
    assert_select "[data-testid='privacy-content']", text: /rectification/i
    assert_select "[data-testid='privacy-content']", text: /effacement/i
    assert_select "[data-testid='privacy-content']", text: /limitation/i
    assert_select "[data-testid='privacy-content']", text: /opposition/i
    assert_select "[data-testid='privacy-content']", text: /portabilité/i
    assert_select "[data-testid='privacy-content']", text: /décision automatisée/i
  end

  test "FR privacy page includes DPD contact info" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.dpd_title", locale: :fr)}/
    assert_select "[data-testid='privacy-content']", text: /Adrien Maré/
  end

  test "FR privacy page includes cookies section" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.cookies_title", locale: :fr)}/
  end

  test "FR privacy page includes APDP complaint right" do
    get "/confidentialite"
    assert_select "h2", text: /#{I18n.t("privacy.complaint_title", locale: :fr)}/
    assert_select "[data-testid='privacy-content']", text: /APDP/
  end

  # === All locales render ===

  test "EN privacy page renders translated content" do
    get "/en/privacy"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :en)}/
    assert_select "h2", text: /#{I18n.t("privacy.controller_title", locale: :en)}/
    assert_select "h2", text: /#{I18n.t("privacy.rights_title", locale: :en)}/
  end

  test "IT privacy page renders translated content" do
    get "/it/privacy"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :it)}/
  end

  test "DE privacy page renders translated content" do
    get "/de/datenschutz"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :de)}/
  end

  test "SV privacy page renders translated content" do
    get "/sv/integritet"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :sv)}/
  end

  test "NO privacy page renders translated content" do
    get "/no/personvern"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :no)}/
  end

  test "DA privacy page renders translated content" do
    get "/da/privatlivspolitik"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :da)}/
  end

  test "FI privacy page renders translated content" do
    get "/fi/tietosuoja"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :fi)}/
  end

  test "RU privacy page renders translated content" do
    get "/ru/konfidentsialnost"
    assert_response :success
    assert_select "h1", text: /#{I18n.t("privacy.title", locale: :ru)}/
  end
end
