require "test_helper"

class ExchangeRateRefreshJobTest < ActiveJob::TestCase
  test "job calls CurrencyConverter.refresh" do
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
      ExchangeRateRefreshJob.perform_now
    end
  end
end
