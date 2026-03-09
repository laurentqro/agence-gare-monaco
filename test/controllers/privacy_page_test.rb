require "test_helper"

class PrivacyPageTest < ActionDispatch::IntegrationTest
  test "FR privacy page renders policy content" do
    get "/confidentialite"
    assert_response :success
    assert_select "h1", text: /Politique de Confidentialité/i
    assert_select "[data-testid='privacy-content']"
  end

  test "privacy page includes key sections" do
    get "/confidentialite"
    assert_response :success
    assert_select "h2", text: /Responsable du traitement/
    assert_select "h2", text: /Type de données collectées/
    assert_select "h2", text: /Finalité de la collecte/
    assert_select "h2", text: /Confidentialité des données/
    assert_select "h2", text: /Durée de conservation/
    assert_select "h2", text: /Droits des utilisateurs/
    assert_select "h2", text: /Cookies/
    assert_select "h2", text: /Balises internet/
  end

  test "EN privacy page renders policy content" do
    get "/en/privacy"
    assert_response :success
    assert_select "h1", text: /Politique de Confidentialité/i
  end
end
