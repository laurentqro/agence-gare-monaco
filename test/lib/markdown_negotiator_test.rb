require "test_helper"
require "markdown_negotiator"

class MarkdownNegotiatorTest < ActiveSupport::TestCase
  PREFERS_MARKDOWN = [
    "text/markdown",
    "text/markdown, text/html, */*",
    "text/markdown, text/html",
    "text/html;q=0.8, text/markdown;q=0.9",
    "text/markdown;q=0.9, */*;q=0.1",
    "TEXT/MARKDOWN",
    "text/markdown; charset=utf-8, text/html;q=0.5"
  ].freeze

  PREFERS_HTML = [
    nil,
    "",
    "*/*",
    "text/*",
    "text/html",
    "text/html, text/markdown",
    "text/html, text/markdown, */*",
    "text/markdown;q=0.8, text/html;q=0.9",
    "text/markdown;q=0",
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "application/json"
  ].freeze

  test "appends Accept to an existing Vary header" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8", "vary" => "Accept-Encoding" }, [ "<main><p>Hi</p></main>" ] ] }
    _status, headers, _body = MarkdownNegotiator.new(app).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal "Accept-Encoding, Accept", headers["vary"]
  end

  test "does not duplicate Accept in Vary" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8", "vary" => "accept" }, [ "<main><p>Hi</p></main>" ] ] }
    _status, headers, _body = MarkdownNegotiator.new(app).call(Rack::MockRequest.env_for("/"))
    assert_equal "accept", headers["vary"]
  end

  test "rewrites the downstream Accept header to text/html when markdown wins" do
    seen = nil
    app = ->(env) { seen = env["HTTP_ACCEPT"]; [ 200, { "content-type" => "text/html" }, [ "<main>x</main>" ] ] }
    MarkdownNegotiator.new(app).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown, text/html"))
    assert_equal "text/html", seen
  end

  test "leaves POST requests alone" do
    app = ->(_env) { [ 200, { "content-type" => "text/html" }, [ "<main>x</main>" ] ] }
    _status, headers, body = MarkdownNegotiator.new(app).call(Rack::MockRequest.env_for("/", method: "POST", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal "text/html", headers["content-type"]
    assert_equal [ "<main>x</main>" ], body
  end

  PREFERS_MARKDOWN.each do |accept|
    test "prefers markdown for #{accept.inspect}" do
      assert MarkdownNegotiator.prefers_markdown?(accept), "expected #{accept.inspect} to prefer markdown"
    end
  end

  PREFERS_HTML.each do |accept|
    test "prefers html for #{accept.inspect}" do
      assert_not MarkdownNegotiator.prefers_markdown?(accept), "expected #{accept.inspect} to prefer html"
    end
  end
end
