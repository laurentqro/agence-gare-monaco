require "test_helper"

class FaqPageTest < ActionDispatch::IntegrationTest
  test "FAQ page renders successfully for French" do
    get "/faq"
    assert_response :success
    assert_select "h1", text: /FAQ|Questions/
  end

  test "FAQ page renders successfully for English" do
    get "/en/faq"
    assert_response :success
    assert_select "h1", text: /FAQ|Questions/
  end

  test "FAQ page displays all FAQ items" do
    get "/faq"
    assert_select "[data-testid='faq-item']", { minimum: 5 }
  end

  test "FAQ page includes FAQPage JSON-LD" do
    get "/faq"
    assert_select "script[type='application/ld+json']" do |scripts|
      faq_script = scripts.find { |s| s.text.include?('"FAQPage"') }
      assert faq_script, "Expected FAQPage JSON-LD on FAQ page"
      parsed = JSON.parse(faq_script.text)
      assert_equal "FAQPage", parsed["@type"]
      assert parsed["mainEntity"].length >= 5
    end
  end

  test "FAQ page has correct meta description" do
    get "/faq"
    assert_select "meta[name='description']" do |tags|
      assert_match(/1942/, tags.first["content"])
    end
  end

  test "FAQ page renders for all locales" do
    get "/faq"
    assert_response :success

    %w[en it de sv no da fi].each do |locale|
      get "/#{locale}/faq"
      assert_response :success, "FAQ page failed for locale #{locale}"
      assert_select "[data-testid='faq-item']", { minimum: 5 },
        "FAQ items missing for locale #{locale}"
    end
  end
end
