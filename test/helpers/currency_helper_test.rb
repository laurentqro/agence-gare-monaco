require "test_helper"

class CurrencyHelperTest < ActionView::TestCase
  include CurrencyHelper

  test "converted_price_tag returns nil for EUR locale (no conversion needed)" do
    I18n.with_locale(:fr) do
      assert_nil converted_price_tag(1_000_000)
    end
  end

  test "converted_price_tag returns converted price for SEK locale" do
    ExchangeRate.create!(currency: "SEK", rate: 11.25, fetched_at: Time.current)
    I18n.with_locale(:sv) do
      result = converted_price_tag(1_000_000)
      assert_includes result, "11.250.000"
      assert_includes result, "SEK"
    end
  end

  test "converted_price_tag returns converted price for GBP locale" do
    ExchangeRate.create!(currency: "GBP", rate: 0.84, fetched_at: Time.current)
    I18n.with_locale(:en) do
      result = converted_price_tag(1_000_000)
      assert_includes result, "840.000"
      assert_includes result, "GBP"
    end
  end

  test "converted_price_tag returns nil when no exchange rate available" do
    I18n.with_locale(:sv) do
      assert_nil converted_price_tag(1_000_000)
    end
  end

  test "converted_price_tag returns nil when price is nil" do
    assert_nil converted_price_tag(nil)
  end

  test "format_converted_price uses European number formatting" do
    assert_equal "11.250.000", format_converted_price(11_250_000)
  end

  test "format_converted_price handles small numbers" do
    assert_equal "840", format_converted_price(840)
  end
end
