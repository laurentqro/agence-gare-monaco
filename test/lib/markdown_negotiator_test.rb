require "test_helper"
require "markdown_negotiator"

class MarkdownNegotiatorTest < ActiveSupport::TestCase
  BASE = "https://agencegaremonaco.com".freeze

  test "absolutises links against the configured host, not forwarded headers" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8" }, [ '<main><a href="/en/sales">Sales</a></main>' ] ] }
    env = Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown", "HTTP_X_FORWARDED_HOST" => "evil.example", "HTTP_X_FORWARDED_PROTO" => "https", "HTTP_HOST" => "evil.example")
    _status, _headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(env)
    assert_equal [ "[Sales](https://agencegaremonaco.com/en/sales)" ], body
  end

  PREFERS_MARKDOWN = [
    "text/markdown",
    "text/markdown, text/html, */*",
    "text/markdown, text/html",
    "text/html;q=0.8, text/markdown;q=0.9",
    "text/markdown;q=0.9, */*;q=0.1",
    "text/markdown;q=0.9, text/html;q=0.8, */*;q=1",
    "text/markdown;q=0.9, text/html;q=0.8, text/*;q=1",
    "text/html;q=0, text/*;q=0.5, */*;q=1",
    "TEXT/MARKDOWN",
    "text/markdown; charset=utf-8, text/html;q=0.5",
    "text/html; level=1; q=0.4, text/markdown; q=0.6",
    ",text/markdown",
    "text/markdown,,text/html"
  ].freeze

  PREFERS_HTML = [
    nil,
    "",
    ",text/html",
    ";q=0.5",
    "text/markdown; charset=utf-8; q=0.5, text/html",
    "*/*",
    "text/*",
    "text/html",
    "text/html, text/markdown",
    "text/html, text/markdown, */*",
    "text/markdown;q=0.8, text/html;q=0.9",
    "text/markdown;q=0",
    "text/markdown;q=0, */*;q=1",
    "text/markdown;q=0.8, text/html;q=0.9, */*;q=1",
    "text/markdown;q=0.8, text/*;q=0.9, */*;q=1",
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
    "application/json"
  ].freeze

  test "appends Accept to an existing Vary header" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8", "vary" => "Accept-Encoding" }, [ "<main><p>Hi</p></main>" ] ] }
    _status, headers, _body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal "Accept-Encoding, Accept", headers["vary"]
  end

  test "does not duplicate Accept in Vary" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8", "vary" => "accept" }, [ "<main><p>Hi</p></main>" ] ] }
    _status, headers, _body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/"))
    assert_equal "accept", headers["vary"]
  end

  test "rewrites the downstream Accept header to text/html when markdown wins" do
    seen = nil
    app = ->(env) { seen = env["HTTP_ACCEPT"]; [ 200, { "content-type" => "text/html" }, [ "<main>x</main>" ] ] }
    MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown, text/html"))
    assert_equal "text/html", seen
  end

  test "falls back to the html response when the page cannot be converted" do
    html = "<main>#{"<blockquote>" * 500}deep#{"</blockquote>" * 500}</main>"
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ] }
    status, headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal 200, status
    assert_equal "text/html; charset=utf-8", headers["content-type"]
    assert_equal "Accept", headers["vary"]
    assert_equal [ html ], body
  end

  test "answers 304 when the client already holds the markdown ETag" do
    app = ->(_env) { [ 200, { "content-type" => "text/html; charset=utf-8" }, [ "<main><p>Hi</p></main>" ] ] }
    _status, headers, _body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown"))
    status, headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown", "HTTP_IF_NONE_MATCH" => headers["etag"]))
    assert_equal 304, status
    assert_equal [], body
    assert_nil headers["content-length"]
    assert_nil headers["content-type"]
  end

  test "gives HEAD requests the same markdown headers as GET" do
    seen_method = nil
    app = lambda do |env|
      seen_method = env["REQUEST_METHOD"]
      [ 200, { "content-type" => "text/html; charset=utf-8" }, [ "<main><p>Hi</p></main>" ] ]
    end
    _status, get_headers, _body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", "HTTP_ACCEPT" => "text/markdown"))
    status, head_headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", method: "HEAD", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal 200, status
    assert_equal [], body
    assert_equal "GET", seen_method
    assert_equal get_headers["etag"], head_headers["etag"]
    assert_equal get_headers["content-length"], head_headers["content-length"]
    assert_equal "text/markdown; charset=utf-8", head_headers["content-type"]
  end

  test "leaves POST requests alone" do
    app = ->(_env) { [ 200, { "content-type" => "text/html" }, [ "<main>x</main>" ] ] }
    _status, headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/", method: "POST", "HTTP_ACCEPT" => "text/markdown"))
    assert_equal "text/html", headers["content-type"]
    assert_equal [ "<main>x</main>" ], body
  end

  test "suppresses and closes non-html HEAD bodies without consuming them" do
    upstream_body = Object.new
    closed = false
    upstream_body.define_singleton_method(:close) { closed = true }
    upstream_body.define_singleton_method(:each) { raise "HEAD body should not be consumed" }
    headers = { "content-type" => "text/plain", "content-length" => "42" }
    app = lambda do |env|
      assert_equal "GET", env["REQUEST_METHOD"]
      [ 200, headers, upstream_body ]
    end

    status, head_headers, body = MarkdownNegotiator.new(app, base_url: BASE).call(Rack::MockRequest.env_for("/llms.txt", method: "HEAD", "HTTP_ACCEPT" => "text/markdown"))

    assert_equal 200, status
    assert_equal headers, head_headers
    assert_equal [], body
    assert closed, "discarded response body must be closed"
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
