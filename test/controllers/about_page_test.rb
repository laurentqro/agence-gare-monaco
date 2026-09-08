require "test_helper"

class AboutPageTest < ActionDispatch::IntegrationTest
  ABOUT_PATHS = {
    fr: "/a-propos", en: "/en/about", it: "/it/chi-siamo", de: "/de/ueber-uns", sv: "/sv/om-oss",
    no: "/no/om-oss", da: "/da/om-os", fi: "/fi/tietoa-meista", ru: "/ru/o-nas"
  }.freeze

  test "FR about page renders at /a-propos" do
    get "/a-propos"
    assert_response :success
    assert_select "h1", text: /Agence Immobili/
    assert_select "[data-testid='about-content']"
  end

  test "about page renders for every locale" do
    ABOUT_PATHS.each do |locale, path|
      get path
      assert_response :success, "about page failed for #{locale}"
      assert_select "html[lang='#{locale}']"
      assert_select "[data-testid='about-content']"
    end
  end

  test "about page carries the history, services and expertise paragraphs" do
    get "/a-propos"
    assert_select "[data-testid='about-content'] [data-citation='history']", text: /1942/
    assert_select "[data-testid='about-content'] [data-citation='services']", text: /gestion/
    assert_select "[data-testid='about-content'] [data-citation='expertise']", text: /notaires/
  end

  test "about page has at least 500 characters of content" do
    ABOUT_PATHS.each_value do |path|
      get path
      text = css_select("[data-testid='about-content']").text.squish
      assert_operator text.length, :>=, 500, "#{path} about content is too short"
    end
  end

  test "about page presents the team with links to member pages" do
    get "/a-propos"
    assert_select "[data-testid='about-team'] a[href='/equipe/pierre-mare']", text: /Pierre Maré/
    assert_select "[data-testid='about-team'] a[href='/equipe/adrien-mare']", text: /Adrien Maré/
    assert_select "[data-testid='about-team'] a[href='/equipe/josiane-alesi']", text: /Josiane Alesi/

    get "/en/about"
    assert_select "[data-testid='about-team'] a[href='/en/team/pierre-mare']"
  end

  test "about page lists the agency facts and a contact link" do
    get "/en/about"
    assert_select "[data-testid='about-facts']", text: /1942/
    assert_select "[data-testid='about-facts']", text: /Chambre Immobilière Monégasque/
    assert_select "[data-testid='about-facts']", text: /3, Rue Langlé/
    assert_select "[data-testid='about-facts']", text: /\+377 93 30 22 36/
    assert_select "[data-testid='about-content'] a[href='/en/contact']"
  end

  test "about page has SEO tags" do
    get "/en/about"
    assert_select "title", text: /About \| Agence Immobilière de la Gare/
    assert_select "meta[name='description'][content*='1942']"
    assert_select "link[rel='canonical'][href='https://agencegaremonaco.com/en/about']"
    assert_select "link[rel='alternate'][hreflang='fr'][href='https://agencegaremonaco.com/a-propos']"
    assert_select "link[rel='alternate'][hreflang='de'][href='https://agencegaremonaco.com/de/ueber-uns']"
    assert_select "link[rel='alternate'][hreflang='x-default'][href='https://agencegaremonaco.com/a-propos']"
    assert_select "meta[property='og:image']"
  end

  test "about page includes AboutPage JSON-LD pointing at the organization" do
    get "/en/about"
    scripts = css_select("script[type='application/ld+json']").map { |s| JSON.parse(s.text) }
    about = scripts.find { |s| s["@type"] == "AboutPage" }
    assert about, "Expected AboutPage JSON-LD"
    assert_equal "https://agencegaremonaco.com/en/about", about["url"]
    assert_equal "https://agencegaremonaco.com/#organization", about["mainEntity"]["@id"]
    assert_equal "en", about["inLanguage"]
  end

  test "/about redirects permanently to the English about page" do
    get "/about"
    assert_response :moved_permanently
    assert_equal "http://www.example.com/en/about", response.location
  end

  test "every locale has the about page translations" do
    I18n.available_locales.each do |locale|
      %w[about.title about.history about.services about.expertise about.facts_title about.founded about.member about.address about.hours
         homepage.about_teaser homepage.about_link nav.about routes.about seo.about_description].each do |key|
        assert I18n.exists?(key, locale), "Missing #{key} for #{locale}"
      end
    end
  end
end
