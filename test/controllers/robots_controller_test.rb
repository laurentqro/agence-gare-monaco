require "test_helper"

class RobotsControllerTest < ActionDispatch::IntegrationTest
  test "robots.txt returns text/plain" do
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
  end

  test "robots.txt allows all crawlers" do
    get "/robots.txt"
    assert_includes response.body, "User-agent: *"
    assert_includes response.body, "Allow: /"
  end

  test "robots.txt disallows admin" do
    get "/robots.txt"
    assert_includes response.body, "Disallow: /admin/"
  end

  test "robots.txt disallows rails internal" do
    get "/robots.txt"
    assert_includes response.body, "Disallow: /rails/"
  end

  test "robots.txt references sitemap" do
    get "/robots.txt"
    assert_includes response.body, "Sitemap: https://agencegaremonaco.com/sitemap.xml"
  end

  test "robots.txt includes GPTBot allow rule" do
    get "/robots.txt"
    assert_includes response.body, "User-agent: GPTBot"
    assert_includes response.body, "Allow: /"
  end

  test "robots.txt includes ClaudeBot allow rule" do
    get "/robots.txt"
    assert_includes response.body, "User-agent: ClaudeBot"
  end

  test "robots.txt includes PerplexityBot allow rule" do
    get "/robots.txt"
    assert_includes response.body, "User-agent: PerplexityBot"
  end

  test "robots.txt includes Google-Extended allow rule" do
    get "/robots.txt"
    assert_includes response.body, "User-agent: Google-Extended"
  end
end
