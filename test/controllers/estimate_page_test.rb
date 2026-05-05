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
    # French locale uses U+2009 thin space as thousands separator
    assert_match(/60\p{Space}?526/, response.body) # price/m²
    assert_match(/6\p{Space}?052\p{Space}?600/, response.body) # total
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
    # low = 4_539_450, high = 7_565_750 (French locale uses U+2009 thin space)
    assert_match(/4\p{Space}?539\p{Space}?450/, response.body)
    assert_match(/7\p{Space}?565\p{Space}?750/, response.body)
  end

  test "result page renders expert contact form posting to contact_submissions" do
    post "/estimer", params: {
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
    post "/estimer", params: {
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024
    }
    assert_response :success
    assert_select "[data-testid='estimate-result'] a[href='https://imsee.mc/thematiques/economie/publications/observatoire-de-l-immobilier'][rel~='noopener']",
      text: /Observatoire de l'Immobilier.*IMSEE.*2026/m
  end

  test "expert form on EN result page submits with EN return_to" do
    post "/en/valuation", params: {
      district: "larvotto",
      surface: 150,
      construction_year: 2022
    }
    assert_response :success
    assert_select "[data-testid='estimate-expert-form']"
    assert_select "input[type='hidden'][name='return_to'][value='estimate']"
  end
end
