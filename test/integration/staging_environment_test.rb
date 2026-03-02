require "test_helper"

class StagingEnvironmentTest < ActionDispatch::IntegrationTest
  # --- Production behavior (default in test) ---

  test "production: robots.txt allows crawling" do
    get "/robots.txt"
    assert_response :success
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Allow: /"
    assert_includes response.body, "Disallow: /admin/"
    assert_includes response.body, "Disallow: /rails/"
    assert_includes response.body, "Sitemap: https://agencegaremonaco.com/sitemap.xml"
    assert_not_includes response.body, "Disallow: /\n"
  end

  test "production: homepage does not have noindex meta tag" do
    get "/"
    assert_response :success
    assert_no_match(/name="robots".*noindex/, response.body)
  end

  test "production: homepage includes Plausible analytics script" do
    get "/"
    assert_response :success
    assert_includes response.body, "plausible.io/js/script.js"
  end

  # --- Staging behavior ---
  # We test staging by temporarily swapping the SITE_HOST constant

  test "staging: robots.txt blocks all crawlers" do
    with_staging_host do
      get "/robots.txt"
      assert_response :success
      assert_includes response.body, "User-agent: *"
      assert_includes response.body, "Disallow: /"
      assert_not_includes response.body, "Allow: /"
      assert_not_includes response.body, "Sitemap:"
    end
  end

  test "staging: homepage has noindex nofollow meta tag" do
    with_staging_host do
      get "/"
      assert_response :success
      assert_select 'meta[name="robots"][content="noindex, nofollow"]'
    end
  end

  test "staging: homepage does not include Plausible analytics script" do
    with_staging_host do
      get "/"
      assert_response :success
      assert_not_includes response.body, "plausible.io/js/script.js"
    end
  end

  test "staging: property listing page has noindex meta tag" do
    district = District.create!(name: "Test District", city: "Monaco", slug: "test-district")
    Property.create!(
      reference: "STG-001", title: { "en" => "Staging Test" }, transaction_type: "sale",
      property_type: "apartment", country: "MC", city: "Monaco", published: true,
      district: district
    )

    with_staging_host do
      get "/en/sales/monaco"
      assert_response :success
      assert_select 'meta[name="robots"][content="noindex, nofollow"]'
    end
  end

  private

  def with_staging_host
    original = SeoHelper::SITE_HOST
    SeoHelper.send(:remove_const, :SITE_HOST)
    SeoHelper.const_set(:SITE_HOST, "https://curau.dev")
    yield
  ensure
    SeoHelper.send(:remove_const, :SITE_HOST)
    SeoHelper.const_set(:SITE_HOST, original)
  end
end
