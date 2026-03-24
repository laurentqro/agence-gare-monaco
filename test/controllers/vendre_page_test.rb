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
    assert_select "h2", text: /estimer la valeur/i
    assert_select "h2", text: /documents.*nécessaires/i
    assert_select "h2", text: /mandat de vente/i
    assert_select "h2", text: /Comment vendons-nous/i
    assert_select "h2", text: /fonds sont-ils versés/i
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
