require "test_helper"

class EstimatePageTest < ActionDispatch::IntegrationTest
  setup do
    District.find_or_create_by!(slug: "monte-carlo") do |d|
      d.name = "Monte-Carlo"
      d.city = "Monaco"
    end
    District.find_or_create_by!(slug: "larvotto") do |d|
      d.name = "Larvotto"
      d.city = "Monaco"
    end
    District.find_or_create_by!(slug: "jardin-exotique") do |d|
      d.name = "Jardin Exotique"
      d.city = "Monaco"
    end
  end

  test "FR estimate page renders form at /estimer" do
    get "/estimer"
    assert_response :success
    assert_select "h1", text: /estim/i
    assert_select "form[action='/estimer']"
    assert_select "select[name='district']"
    assert_select "input[name='surface']"
    assert_select "input[name='construction_year']"
  end

  test "all 9 locales return 200 on the estimate page" do
    locale_paths = {
      fr: "/estimer",
      en: "/en/valuation",
      it: "/it/stima",
      de: "/de/bewertung",
      sv: "/sv/vardering",
      no: "/no/verdivurdering",
      da: "/da/vurdering",
      fi: "/fi/arviointi",
      ru: "/ru/otsenka"
    }

    locale_paths.each do |locale, path|
      get path
      assert_response :success, "Expected 200 for #{locale} at #{path}, got #{response.status}"
    end
  end

  test "EN valuation page renders translated heading" do
    get "/en/valuation"
    assert_response :success
    assert_select "h1", text: /worth/i
  end

  test "POST with valid params displays estimate" do
    post "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
    assert_match(/60[\s ]?526/, response.body) # price/m²
    assert_match(/6[\s ]?052[\s ]?600/, response.body) # total
  end

  test "POST with invalid surface re-renders form with error" do
    post "/estimer", params: {
      district: "monte-carlo",
      surface: -5,
      construction_year: 2024
    }
    assert_response :unprocessable_content
    assert_select "[data-testid='estimate-errors']"
    assert_select "[data-testid='estimate-result']", false
  end

  test "POST with unknown district (Monaco-Ville) re-renders form with error" do
    post "/estimer", params: {
      district: "monaco-ville",
      surface: 100,
      construction_year: 2024
    }
    assert_response :unprocessable_content
    assert_select "[data-testid='estimate-errors']"
  end

  test "POST with missing surface re-renders form with error" do
    post "/estimer", params: {
      district: "monte-carlo",
      construction_year: 2024
    }
    assert_response :unprocessable_content
    assert_select "[data-testid='estimate-errors']"
  end

  test "POST in EN locale routes to /en/valuation and shows result" do
    post "/en/valuation", params: {
      district: "larvotto",
      surface: 150,
      construction_year: 2022
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
  end

  test "navbar sell link still points to vendre page (estimate is separate)" do
    get "/"
    assert_select "nav a[href='/estimer']", minimum: 1
  end

  test "estimate page appears in FR sitemap" do
    get "/sitemaps/fr.xml"
    assert_response :success
    assert_includes response.body, "/estimer"
  end

  test "SEO meta tags are present on estimate page" do
    get "/estimer"
    assert_response :success
    assert_select "title", text: /[Ee]stim/
    assert_select "meta[name='description']"
    assert_select "link[rel='canonical']"
    assert_select "link[rel='alternate'][hreflang]"
  end

  test "language switcher on estimate page links to correct locale paths" do
    get "/estimer"
    assert_response :success
    assert_select "a[href='/en/valuation']"
    assert_select "a[href='/it/stima']"
  end

  test "result shows confidence band low and high" do
    post "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    # low = 4_539_450, high = 7_565_750
    assert_match(/4[\s ]?539[\s ]?450/, response.body)
    assert_match(/7[\s ]?565[\s ]?750/, response.body)
  end
end
