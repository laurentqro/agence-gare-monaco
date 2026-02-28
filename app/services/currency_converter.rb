class CurrencyConverter
  API_URL = "https://api.frankfurter.dev/v1/latest".freeze
  CURRENCIES = %w[SEK NOK DKK GBP CHF USD].freeze

  def self.refresh
    new.refresh
  end

  def refresh
    response = fetch_rates
    return unless response

    now = Time.current
    response.each do |currency, rate|
      record = ExchangeRate.find_or_initialize_by(currency: currency)
      record.update!(rate: rate, fetched_at: now)
    end
  end

  private

  def fetch_rates
    uri = URI("#{API_URL}?base=EUR&symbols=#{CURRENCIES.join(',')}")
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data["rates"]
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
    Rails.logger.error("CurrencyConverter: Failed to fetch exchange rates — #{e.message}")
    nil
  end
end
