require "test_helper"

class VendrePageTest < ActionDispatch::IntegrationTest
  test "FR vendre page renders at /vendre" do
    get "/vendre"
    assert_response :success
    assert_select "h1", text: /vendre.*bien.*Monaco/i
    assert_select "[data-testid='vendre-content']"
  end

  test "vendre page includes key sections" do
    get "/vendre"
    assert_response :success
    assert_select "h2", text: /Estimez la valeur de votre bien/i
    assert_select "h2", text: /partie administrative de la vente/i
    assert_select "h2", text: /mandat de vente/i
    assert_select "h2", text: /Comment vendons-nous/i
    assert_select "h2", text: /Le versement des fonds/i
  end

  test "all 9 locales return 200" do
    locale_paths = {
      fr: "/vendre",
      en: "/en/sell",
      it: "/it/vendere",
      de: "/de/verkaufen",
      sv: "/sv/salja",
      no: "/no/selge",
      da: "/da/saelg",
      fi: "/fi/myy",
      ru: "/ru/prodat"
    }

    locale_paths.each do |locale, path|
      get path
      assert_response :success, "Expected 200 for #{locale} at #{path}, got #{response.status}"
    end
  end

  test "EN vendre page renders translated title" do
    get "/en/sell"
    assert_response :success
    assert_select "h1", text: /sell.*property.*Monaco/i
  end

  test "navbar sell link points to vendre page" do
    get "/"
    assert_select "nav a[href='/vendre']", minimum: 1
  end

  test "homepage sell card links to vendre page" do
    get "/"
    assert_select "a[href='/vendre']", minimum: 1
  end

  test "language switcher on vendre page links to correct locale paths" do
    get "/vendre"
    assert_response :success
    assert_select "a[href='/en/sell']"
    assert_select "a[href='/it/vendere']"
  end

  test "SEO meta tags are present on vendre page" do
    get "/vendre"
    assert_response :success
    assert_select "title", text: /Vendre/i
    assert_select "meta[name='description']"
    assert_select "link[rel='canonical']"
    assert_select "link[rel='alternate'][hreflang]"
  end

  test "vendre page appears in sitemap" do
    get "/sitemaps/fr.xml"
    assert_response :success
    assert_includes response.body, "/vendre"
  end

  test "FR vendre page uses verbatim article content" do
    get "/vendre"
    assert_response :success
    body = response.body
    assert_includes body, "Une bonne estimation de votre bien permettra de conclure une vente rapide"
    assert_includes body, "Nous prenons tout en charge pour que votre expérience soit la plus agréable possible."
    assert_includes body, "votre attestation de propriété du bien à vendre,"
    assert_includes body, "les trois derniers procès-verbaux de l&#39;assemblée générale de copropriété,"
    assert_includes body, "Ce type de mandat vous permet de confier la vente de votre bien à plusieurs agences immobilières"
    assert_includes body, "Le mandat de vente exclusif confie la vente du bien à une seule agence immobilière."
    assert_includes body, "Le mandat co-exclusif peut être la solution hybride"
    assert_includes body, "vidéos HD et photos HD en 360°"
    assert_includes body, "les fonds vous seront versés par l&#39;étude notariale sous 15 jours"
    assert_select "h2", text: /Estimez la valeur de votre bien/i
    assert_select "h2", text: /Nous gérons toute la partie administrative/i
    assert_select "h2", text: /Le versement des fonds/i
  end

  test "vendre page includes FAQPage JSON-LD schema" do
    get "/vendre"
    assert_response :success
    assert_select "script[type='application/ld+json']" do |scripts|
      faq_script = scripts.find { |s| s.text.include?("FAQPage") }
      assert faq_script, "Expected FAQPage JSON-LD to be present"
      parsed = JSON.parse(faq_script.text)
      assert_equal "FAQPage", parsed["@type"]
      assert parsed["mainEntity"].is_a?(Array)
      assert parsed["mainEntity"].size >= 2
      parsed["mainEntity"].each do |item|
        assert_equal "Question", item["@type"]
        assert item["name"].present?
        assert_equal "Answer", item["acceptedAnswer"]["@type"]
        assert item["acceptedAnswer"]["text"].present?
      end
    end
  end
end
