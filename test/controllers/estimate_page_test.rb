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

  test "FR estimate page renders form at /estimer with localized FR field names" do
    get "/estimer"
    assert_response :success
    assert_select "h1", text: /estim/i
    assert_select "form[action='/estimer']"
    assert_select "select[name='quartier']"
    assert_select "input[name='surface']"
    assert_select "input[name='annee-construction']"
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

  test "GET with unknown district (Monaco-Ville) re-renders form with error" do
    get "/estimer", params: {
      district: "monaco-ville",
      surface: 100,
      construction_year: 2024
    }
    assert_response :unprocessable_content
    assert_select "[data-testid='estimate-errors']"
  end

  test "GET with district + missing surface treats it as the empty form (no error, no result)" do
    # Partial query strings (e.g. someone fiddling with the URL) should not produce a noisy
    # error page — only fully populated requests trigger validation.
    get "/estimer", params: {
      district: "monte-carlo",
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']", false
    assert_select "[data-testid='estimate-errors']", false
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
    get "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    # low = 4_539_450, high = 7_565_750 (French locale uses U+2009 thin space)
    assert_match(/4\p{Space}?539\p{Space}?450/, response.body)
    assert_match(/7\p{Space}?565\p{Space}?750/, response.body)
  end

  test "GET /estimer with valid query params renders the result so the URL is shareable" do
    get "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
    # Same numbers as the POST result
    assert_match(/60\p{Space}?526/, response.body)
    assert_match(/6\p{Space}?052\p{Space}?600/, response.body)
  end

  test "the input form is also rendered above the result, prefilled, so the user can tweak and re-submit" do
    get "/estimer", params: {
      "quartier" => "monte-carlo",
      "surface" => 100,
      "annee-construction" => 2024
    }
    assert_response :success
    # Form is visible above the result, using FR-localized field names
    assert_select "form[action='/estimer'][method='get'] select[name='quartier'] option[selected][value='monte-carlo']"
    assert_select "form[action='/estimer'][method='get'] input[name='surface'][value='100']"
    assert_select "form[action='/estimer'][method='get'] input[name='annee-construction'][value='2024']"
    assert_select "[data-testid='estimate-result']"
  end

  test "GET with no params still renders the empty form (no result)" do
    get "/estimer"
    assert_response :success
    assert_select "[data-testid='estimate-result']", false
    assert_select "form select[name='quartier']"
  end

  test "GET with invalid surface re-renders the form with errors" do
    get "/estimer", params: {
      district: "monte-carlo",
      surface: -5,
      construction_year: 2024
    }
    assert_response :unprocessable_content
    assert_select "[data-testid='estimate-errors']"
  end

  test "form on the estimate page submits via GET so the result URL is shareable" do
    get "/estimer"
    assert_select "form[action='/estimer'][method='get']"
  end

  test "old English query keys (district/surface/construction_year) still work as a fallback so legacy shared URLs don't break" do
    get "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
  end

  test "FR uses localized query keys (quartier, surface, annee-construction)" do
    get "/estimer", params: {
      "quartier" => "monte-carlo",
      "surface" => 100,
      "annee-construction" => 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
    assert_match(/60\p{Space}?526/, response.body)
    # Form submits with FR-localized field names
    assert_select "form select[name='quartier']"
    assert_select "form input[name='surface']"
    assert_select "form input[name='annee-construction']"
  end

  test "EN uses EN-localized query keys (district, area, construction-year)" do
    get "/en/valuation", params: {
      "district" => "larvotto",
      "area" => 150,
      "construction-year" => 2022
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
    assert_select "form select[name='district']"
    assert_select "form input[name='area']"
    assert_select "form input[name='construction-year']"
  end

  test "IT uses IT-localized query keys (quartiere, superficie, anno-costruzione)" do
    get "/it/stima", params: {
      "quartiere" => "monte-carlo",
      "superficie" => 100,
      "anno-costruzione" => 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
    assert_select "form select[name='quartiere']"
  end

  test "language switcher rewrites query keys to the target locale so a shared estimate stays the same" do
    get "/estimer", params: {
      "quartier" => "monte-carlo",
      "surface" => 100,
      "annee-construction" => 2024
    }
    assert_response :success
    # When switching to EN, keys must be rewritten to district/area/construction-year
    assert_select "a[href='/en/valuation?area=100&construction-year=2024&district=monte-carlo']"
    # When switching to IT, keys rewrite to quartiere/superficie/anno-costruzione
    assert_select "a[href='/it/stima?anno-costruzione=2024&quartiere=monte-carlo&superficie=100']"
  end

  test "GET in EN locale also renders shareable result" do
    get "/en/valuation", params: {
      district: "larvotto",
      surface: 150,
      construction_year: 2022
    }
    assert_response :success
    assert_select "[data-testid='estimate-result']"
  end

  test "result page renders expert contact form posting to contact_submissions" do
    get "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-expert-form'] form[action^='/contact_submissions']"
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "input[name='contact_submission[phone]']"
    # Form intentionally has no message field — the server fills it from the estimate inputs.
    assert_select "textarea[name='contact_submission[message]']", false
    # Carries the inputs that produced the estimate so the agent has full context
    assert_select "input[type='hidden'][name='estimate[district]'][value='monte-carlo']"
    assert_select "input[type='hidden'][name='estimate[surface]'][value='100']"
    assert_select "input[type='hidden'][name='estimate[construction_year]'][value='2024']"
    assert_select "input[type='hidden'][name='return_to'][value='estimate']"
  end

  test "submitting the expert contact form from estimate creates a submission and redirects back to the estimate page" do
    assert_difference -> { ContactSubmission.count }, 1 do
      post "/contact_submissions", params: {
        contact_submission: {
          name: "Sophie Martin",
          email: "sophie@example.com",
          phone: "+33 6 12 34 56 78"
        },
        return_to: "estimate",
        estimate: {
          district: "monte-carlo",
          surface: "100",
          construction_year: "2024"
        },
        locale: "fr"
      }
    end
    submission = ContactSubmission.last
    # The server auto-fills the message body from the estimate inputs so the agent
    # has full context even though the form only collects name + phone + email.
    assert_match(/Monte-Carlo/, submission.message)
    assert_match(/100/, submission.message)
    assert_match(/2024/, submission.message)
    assert_redirected_to "/estimer"
    follow_redirect!
    assert_match(/estim/i, response.body)
  end

  test "expert contact form submitted without name or email re-renders the result with errors and preserves the estimate" do
    post "/contact_submissions", params: {
      contact_submission: {
        name: "",
        email: "",
        phone: ""
      },
      return_to: "estimate",
      estimate: {
        district: "monte-carlo",
        surface: "100",
        construction_year: "2024"
      },
      locale: "fr"
    }
    assert_response :unprocessable_content
    # The estimate result is restored alongside the form errors
    assert_select "[data-testid='estimate-result']"
    assert_select "[data-testid='estimate-expert-form']"
    assert_select "[data-testid='form-errors']"
    # Inputs are preserved so the user can fix the broken field without losing context
    assert_select "input[type='hidden'][name='estimate[district]'][value='monte-carlo']"
  end

  test "result page credits IMSEE Observatoire de l'Immobilier with a link to the source" do
    get "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result'] a[href='https://imsee.mc/thematiques/economie/publications/observatoire-de-l-immobilier'][rel~='noopener']",
      text: /Observatoire de l'Immobilier.*IMSEE.*2026/m
  end

  test "expert form on EN result page submits with EN return_to" do
    get "/en/valuation", params: {
      district: "larvotto",
      surface: 150,
      construction_year: 2022
    }
    assert_response :success
    assert_select "[data-testid='estimate-expert-form']"
    assert_select "input[type='hidden'][name='return_to'][value='estimate']"
  end
end
