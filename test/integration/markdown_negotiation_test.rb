require "test_helper"

class MarkdownNegotiationTest < ActionDispatch::IntegrationTest
  MARKDOWN = "text/markdown; charset=utf-8".freeze
  HTML = "text/html; charset=utf-8".freeze

  test "serves markdown when the client asks for text/markdown" do
    get "/", headers: { "Accept" => "text/markdown" }
    assert_response :success
    assert_equal MARKDOWN, response.content_type
    assert_includes response.body, "# "
    assert_includes response.body, "vente, location et gestion"
    assert_no_match(/<(div|main|html|script)\b/i, response.body)
  end

  test "serves markdown when text/markdown is listed first alongside text/html and */*" do
    get "/", headers: { "Accept" => "text/markdown, text/html, */*" }
    assert_equal MARKDOWN, response.content_type
  end

  test "honours q-values that prefer markdown" do
    get "/", headers: { "Accept" => "text/html;q=0.8, text/markdown;q=0.9" }
    assert_equal MARKDOWN, response.content_type
  end

  test "honours q-values that prefer html" do
    get "/", headers: { "Accept" => "text/markdown;q=0.8, text/html;q=0.9" }
    assert_equal HTML, response.content_type
  end

  test "uses explicit media range quality before wildcard quality" do
    get "/", headers: { "Accept" => "text/markdown;q=0.9, text/html;q=0.8, */*;q=1" }
    assert_response :success
    assert_equal MARKDOWN, response.content_type
  end

  test "serves html to browsers" do
    get "/", headers: { "Accept" => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" }
    assert_equal HTML, response.content_type
  end

  test "serves html when no Accept header is sent" do
    get "/"
    assert_equal HTML, response.content_type
  end

  test "serves html for Accept: */*" do
    get "/", headers: { "Accept" => "*/*" }
    assert_equal HTML, response.content_type
  end

  test "sets Vary: Accept on both representations" do
    get "/", headers: { "Accept" => "text/markdown" }
    assert_includes vary_values, "accept"

    get "/", headers: { "Accept" => "text/html" }
    assert_includes vary_values, "accept"
  end

  test "gives each representation its own ETag" do
    get "/", headers: { "Accept" => "text/html" }
    html_etag = response.headers["ETag"]
    get "/", headers: { "Accept" => "text/markdown" }
    assert_not_equal html_etag, response.headers["ETag"]
  end

  test "reports the markdown content type, ETag and length on HEAD requests" do
    get "/", headers: { "Accept" => "text/markdown" }
    etag = response.headers["ETag"]

    head "/", headers: { "Accept" => "text/markdown" }
    assert_response :success
    assert_equal MARKDOWN, response.content_type
    assert_includes vary_values, "accept"
    assert_equal etag, response.headers["ETag"]
  end

  test "revalidates the markdown representation with a 304" do
    get "/", headers: { "Accept" => "text/markdown" }
    get "/", headers: { "Accept" => "text/markdown", "If-None-Match" => response.headers["ETag"] }
    assert_response :not_modified
  end

  test "renders the property detail page as markdown with absolute links" do
    district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    property = Property.create!(
      reference: "MC-100",
      title: { "fr" => "Studio vue mer Carré d'Or", "en" => "Sea view studio Carré d'Or" },
      description: { "fr" => "Magnifique studio avec vue mer.", "en" => "Beautiful sea view studio." },
      transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      district: district, price: 1_850_000, currency: "EUR", published: true
    )

    get "/en/properties/#{property.to_param}", headers: { "Accept" => "text/markdown" }
    assert_response :success
    assert_equal MARKDOWN, response.content_type
    assert_includes response.body, "# Sea view studio Carré d'Or"
    assert_includes response.body, "Beautiful sea view studio."
    assert_no_match(/\]\(\/[^)]*\)/, response.body, "relative links must be absolutised")
  end

  test "negotiates the admin login page like any other html page" do
    get "/admin/login", headers: { "Accept" => "text/markdown" }
    assert_response :success
    assert_equal MARKDOWN, response.content_type
  end

  test "does not convert non-html responses" do
    get "/llms.txt", headers: { "Accept" => "text/markdown" }
    assert_equal "text/plain; charset=utf-8", response.content_type

    get "/sitemap.xml", headers: { "Accept" => "text/markdown" }
    assert_equal "application/xml; charset=utf-8", response.content_type
  end

  test "suppresses non-html response bodies on HEAD requests" do
    { "/llms.txt" => "text/plain; charset=utf-8", "/sitemap.xml" => "application/xml; charset=utf-8" }.each do |path, content_type|
      head path, headers: { "Accept" => "text/markdown" }
      assert_response :success
      assert_equal content_type, response.content_type
      assert_empty response.body
    end
  end

  private

  def vary_values
    response.headers["Vary"].to_s.downcase.split(",").map(&:strip)
  end
end
