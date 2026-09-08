require "test_helper"

class LlmsControllerTest < ActionDispatch::IntegrationTest
  test "llms.txt returns text/plain" do
    get "/llms.txt"
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
  end

  test "llms.txt includes agency name" do
    get "/llms.txt"
    assert_includes response.body, "Agence Immobilière de la Gare"
  end

  test "llms.txt includes founding year" do
    get "/llms.txt"
    assert_includes response.body, "1942"
  end

  test "llms.txt includes services" do
    get "/llms.txt"
    assert_includes response.body, "Monaco"
  end

  test "llms.txt includes leadership" do
    get "/llms.txt"
    assert_includes response.body, "Pierre Maré"
    assert_includes response.body, "Adrien Maré"
  end

  test "llms.txt includes contact information" do
    get "/llms.txt"
    assert_includes response.body, "+377 93 30 22 36"
    assert_includes response.body, "info@agencegaremonaco.com"
  end

  test "llms.txt includes website URL" do
    get "/llms.txt"
    assert_includes response.body, "agencegaremonaco.com"
  end

  test "llms.txt tells agents when to use the site" do
    get "/llms.txt"
    assert_match(/^## When to use this site$/, response.body)
    assert_match(/^## When not to use this site$/, response.body)
    assert_includes response.body, "buy, rent or sell"
  end

  test "llms.txt tells agents how to call the site" do
    get "/llms.txt"
    assert_match(/^## How to call this site$/, response.body)
    assert_includes response.body, "Accept: text/markdown"
    assert_includes response.body, "https://agencegaremonaco.com/sitemap.xml"
    assert_includes response.body, "https://agencegaremonaco.com/contact"
  end

  test "llms.txt links the key pages" do
    get "/llms.txt"
    assert_match(/^## Pages$/, response.body)
    %w[/ventes /locations /off-market /articles /contact /confidentialite /faq /estimer /gestion /vendre /equipe/pierre-mare].each do |path|
      assert_includes response.body, "](https://agencegaremonaco.com#{path})"
    end
    assert_includes response.body, "](https://agencegaremonaco.com/en/sales)"
  end

  test "llms.txt follows the llms.txt format" do
    get "/llms.txt"
    lines = response.body.lines.map(&:chomp).reject(&:empty?)
    assert_match(/\A# /, lines.first)
    assert_match(/\A> /, lines.second)
  end
end
