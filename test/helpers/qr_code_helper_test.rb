require "test_helper"

class QrCodeHelperTest < ActionView::TestCase
  test "qr_code_svg returns an SVG string" do
    result = qr_code_svg("https://agencegaremonaco.com/biens/1-test")
    assert_includes result, "<svg"
    assert_includes result, "</svg>"
  end

  test "qr_code_svg sets width and height" do
    result = qr_code_svg("https://example.com", size: 200)
    assert_includes result, 'width="200"'
    assert_includes result, 'height="200"'
  end

  test "qr_code_svg is html_safe" do
    result = qr_code_svg("https://example.com")
    assert result.html_safe?
  end
end
