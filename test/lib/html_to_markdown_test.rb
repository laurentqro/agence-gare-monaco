require "test_helper"
require "html_to_markdown"

class HtmlToMarkdownTest < ActiveSupport::TestCase
  BASE = "https://agencegaremonaco.com".freeze

  def convert(html)
    HtmlToMarkdown.convert(html, base_url: BASE)
  end

  test "converts the main element only" do
    md = convert(<<~HTML)
      <html><body>
        <nav><a href="/">Home</a></nav>
        <main><h1>Ventes</h1><p>Un texte.</p></main>
        <footer>Footer</footer>
      </body></html>
    HTML
    assert_equal "# Ventes\n\nUn texte.", md
  end

  test "falls back to the body when there is no main element" do
    md = convert("<html><body><h1>404</h1><p>Missing</p></body></html>")
    assert_equal "# 404\n\nMissing", md
  end

  test "drops scripts, styles, forms, svg and hidden nodes" do
    md = convert(<<~HTML)
      <main>
        <script>alert(1)</script>
        <style>.a{}</style>
        <svg><path d="M0 0"/></svg>
        <form><input name="email"><button>Envoyer</button></form>
        <div aria-hidden="true">decorative</div>
        <p hidden>secret</p>
        <p>Visible</p>
      </main>
    HTML
    assert_equal "Visible", md
  end

  test "absolutises links and images" do
    md = convert('<main><a href="/en/sales">Sales</a> <img src="/images/logo.png" alt="Logo"></main>')
    assert_includes md, "[Sales](https://agencegaremonaco.com/en/sales)"
    assert_includes md, "![Logo](https://agencegaremonaco.com/images/logo.png)"
  end

  test "keeps absolute links untouched" do
    md = convert('<main><a href="https://example.com/x">X</a></main>')
    assert_includes md, "[X](https://example.com/x)"
  end

  test "renders lists and emphasis" do
    md = convert("<main><ul><li><strong>Bold</strong> item</li><li>Second</li></ul></main>")
    assert_includes md, "- **Bold** item"
    assert_includes md, "- Second"
  end

  test "drops icon-only links that have no text" do
    md = convert(%(<main><a href="mailto:a@b.c" aria-label="Email">\n  <svg></svg>\n</a><a href="/x">Keep</a></main>))
    assert_not_includes md, "mailto:a@b.c"
    assert_includes md, "[Keep](https://agencegaremonaco.com/x)"
  end

  test "prepends the document title when the content has no h1" do
    md = convert("<html><head><title>Contact | Agence</title></head><body><main><h2>Team</h2></main></body></html>")
    assert_equal "# Contact | Agence\n\n## Team", md
  end

  test "does not duplicate the title when the content already has an h1" do
    md = convert("<html><head><title>Ventes | Agence</title></head><body><main><h1>Ventes</h1></main></body></html>")
    assert_equal "# Ventes", md
  end

  test "collapses runs of blank lines" do
    md = convert("<main><div>\n\n\n<p>One</p>\n\n\n\n<div><div><p>Two</p></div></div></div></main>")
    assert_equal "One\n\nTwo", md
  end
end
