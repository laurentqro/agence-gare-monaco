require "test_helper"

class GestionPageTest < ActionDispatch::IntegrationTest
  test "FR gestion page renders at /gestion" do
    get "/gestion"
    assert_response :success
    assert_select "h1", text: /Gestion locative/i
    assert_select "[data-testid='gestion-content']"
  end

  test "gestion page includes key sections" do
    get "/gestion"
    assert_response :success
    assert_select "h2", text: /missions de notre agence/i
    assert_select "h2", text: /publions-nous votre bien/i
    assert_select "h2", text: /contrat de location/i
    assert_select "h2", text: /suivons-nous la vie/i
    assert_select "h2", text: /gérons-nous vos fonds/i
  end

  test "all 8 locales return 200" do
    locale_paths = {
      fr: "/gestion",
      en: "/en/management",
      it: "/it/gestione",
      de: "/de/verwaltung",
      sv: "/sv/forvaltning",
      no: "/no/forvaltning",
      da: "/da/administration",
      fi: "/fi/hallinto"
    }

    locale_paths.each do |locale, path|
      get path
      assert_response :success, "Expected 200 for #{locale} at #{path}, got #{response.status}"
    end
  end

  test "EN gestion page renders translated title" do
    get "/en/management"
    assert_response :success
    assert_select "h1", text: /Property Management/i
  end

  test "navbar management link points to gestion page" do
    get "/"
    assert_select "nav a[href='/gestion']", minimum: 1
  end

  test "footer management link points to gestion page" do
    get "/"
    assert_select "footer a[href='/gestion']", minimum: 1
  end

  test "homepage management card links to gestion page" do
    get "/"
    assert_select "a[href='/gestion']", minimum: 1
  end

  test "language switcher on gestion page links to correct locale paths" do
    get "/gestion"
    assert_response :success
    assert_select "a[href='/en/management']"
    assert_select "a[href='/it/gestione']"
  end

  test "SEO meta tags are present on gestion page" do
    get "/gestion"
    assert_response :success
    assert_select "title", text: /Gestion/i
    assert_select "meta[name='description']"
    assert_select "link[rel='canonical']"
    assert_select "link[rel='alternate'][hreflang]"
  end

  test "gestion page appears in sitemap" do
    get "/sitemaps/fr.xml"
    assert_response :success
    assert_includes response.body, "/gestion"
  end

  test "gestion page includes FAQPage JSON-LD schema" do
    get "/gestion"
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
