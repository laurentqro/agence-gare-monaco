require "test_helper"

class MarkdownHelperTest < ActionView::TestCase
  include MarkdownHelper

  test "renders headings" do
    assert_includes render_markdown("## Heading 2"), "<h2>"
    assert_includes render_markdown("### Heading 3"), "<h3>"
  end

  test "renders bold text" do
    result = render_markdown("**bold text**")
    assert_includes result, "<strong>bold text</strong>"
  end

  test "renders italic text" do
    result = render_markdown("_italic text_")
    assert_includes result, "<em>italic text</em>"
  end

  test "renders links" do
    result = render_markdown("[example](https://example.com)")
    assert_includes result, '<a href="https://example.com">'
    assert_includes result, "example</a>"
  end

  test "renders unordered lists" do
    result = render_markdown("- item one\n- item two")
    assert_includes result, "<ul>"
    assert_includes result, "<li>"
    assert_includes result, "item one"
    assert_includes result, "item two"
  end

  test "renders ordered lists" do
    result = render_markdown("1. first\n2. second")
    assert_includes result, "<ol>"
    assert_includes result, "<li>"
    assert_includes result, "first"
  end

  test "renders blockquotes" do
    result = render_markdown("> quoted text")
    assert_includes result, "<blockquote>"
    assert_includes result, "quoted text"
  end

  test "renders tables" do
    md = "| A | B |\n|---|---|\n| 1 | 2 |"
    result = render_markdown(md)
    assert_includes result, "<table>"
    assert_includes result, "<td>"
  end

  test "renders images" do
    result = render_markdown("![alt text](https://example.com/img.jpg)")
    assert_includes result, "<img"
    assert_includes result, 'alt="alt text"'
    assert_includes result, 'src="https://example.com/img.jpg"'
  end

  test "renders paragraphs" do
    result = render_markdown("Hello world")
    assert_includes result, "<p>"
    assert_includes result, "Hello world"
  end

  test "returns empty string for nil input" do
    assert_equal "", render_markdown(nil)
  end

  test "returns empty string for blank input" do
    assert_equal "", render_markdown("")
    assert_equal "", render_markdown("   ")
  end

  test "returns html_safe string" do
    result = render_markdown("hello")
    assert result.html_safe?
  end
end
