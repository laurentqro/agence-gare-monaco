require "test_helper"

class ExchangeRateTest < ActiveSupport::TestCase
  test "validates presence of currency" do
    rate = ExchangeRate.new(rate: 10.5, fetched_at: Time.current)
    assert_not rate.valid?
    assert_includes rate.errors[:currency], "can't be blank"
  end

  test "validates presence of rate" do
    rate = ExchangeRate.new(currency: "SEK", fetched_at: Time.current)
    assert_not rate.valid?
    assert_includes rate.errors[:rate], "can't be blank"
  end

  test "validates presence of fetched_at" do
    rate = ExchangeRate.new(currency: "SEK", rate: 10.5)
    assert_not rate.valid?
    assert_includes rate.errors[:fetched_at], "can't be blank"
  end

  test "validates uniqueness of currency" do
    ExchangeRate.create!(currency: "SEK", rate: 10.5, fetched_at: Time.current)
    duplicate = ExchangeRate.new(currency: "SEK", rate: 11.0, fetched_at: Time.current)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:currency], "has already been taken"
  end

  test "validates rate is greater than zero" do
    rate = ExchangeRate.new(currency: "SEK", rate: 0, fetched_at: Time.current)
    assert_not rate.valid?
    assert_includes rate.errors[:rate], "must be greater than 0"
  end

  test "convert returns converted amount" do
    ExchangeRate.create!(currency: "SEK", rate: 11.25, fetched_at: Time.current)
    assert_equal 11_250_000, ExchangeRate.convert(1_000_000, "SEK")
  end

  test "convert returns nil for unknown currency" do
    assert_nil ExchangeRate.convert(1_000_000, "XYZ")
  end

  test "convert returns nil for EUR (same currency)" do
    assert_nil ExchangeRate.convert(1_000_000, "EUR")
  end

  test "locale_currency returns correct currency for each locale" do
    assert_equal "SEK", ExchangeRate.locale_currency(:sv)
    assert_equal "NOK", ExchangeRate.locale_currency(:no)
    assert_equal "DKK", ExchangeRate.locale_currency(:da)
    assert_equal "EUR", ExchangeRate.locale_currency(:fr)
    assert_equal "EUR", ExchangeRate.locale_currency(:de)
    assert_equal "EUR", ExchangeRate.locale_currency(:it)
    assert_equal "EUR", ExchangeRate.locale_currency(:fi)
    assert_equal "GBP", ExchangeRate.locale_currency(:en)
  end
end
