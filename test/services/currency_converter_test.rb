require "test_helper"

class CurrencyConverterTest < ActiveSupport::TestCase
  setup do
    WebMock.disable_net_connect!
  end

  teardown do
    WebMock.allow_net_connect!
  end

  test "refresh fetches rates from Frankfurter API and stores them" do
    stub_request(:get, "https://api.frankfurter.dev/v1/latest?base=EUR&symbols=SEK,NOK,DKK,GBP,CHF,USD")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          base: "EUR",
          date: "2026-02-28",
          rates: { SEK: 11.25, NOK: 11.80, DKK: 7.46, GBP: 0.84, CHF: 0.95, USD: 1.08 }
        }.to_json
      )

    assert_difference "ExchangeRate.count", 6 do
      CurrencyConverter.refresh
    end

    sek = ExchangeRate.find_by(currency: "SEK")
    assert_equal 11.25, sek.rate
    assert_not_nil sek.fetched_at
  end

  test "refresh updates existing rates instead of creating duplicates" do
    %w[SEK NOK DKK GBP CHF USD].each do |c|
      ExchangeRate.create!(currency: c, rate: 10.0, fetched_at: 1.day.ago)
    end

    stub_request(:get, "https://api.frankfurter.dev/v1/latest?base=EUR&symbols=SEK,NOK,DKK,GBP,CHF,USD")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          base: "EUR",
          date: "2026-02-28",
          rates: { SEK: 11.25, NOK: 11.80, DKK: 7.46, GBP: 0.84, CHF: 0.95, USD: 1.08 }
        }.to_json
      )

    assert_no_difference "ExchangeRate.count" do
      CurrencyConverter.refresh
    end

    assert_equal 11.25, ExchangeRate.find_by(currency: "SEK").rate
  end

  test "refresh handles API errors gracefully" do
    stub_request(:get, "https://api.frankfurter.dev/v1/latest?base=EUR&symbols=SEK,NOK,DKK,GBP,CHF,USD")
      .to_return(status: 500, body: "Internal Server Error")

    assert_nothing_raised do
      CurrencyConverter.refresh
    end
  end

  test "refresh handles network errors gracefully" do
    stub_request(:get, "https://api.frankfurter.dev/v1/latest?base=EUR&symbols=SEK,NOK,DKK,GBP,CHF,USD")
      .to_timeout

    assert_nothing_raised do
      CurrencyConverter.refresh
    end
  end
end
