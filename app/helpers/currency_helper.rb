module CurrencyHelper
  def converted_price_tag(price_eur)
    return nil if price_eur.blank?

    currency = ExchangeRate.locale_currency(I18n.locale)
    return nil if currency == "EUR"

    converted = ExchangeRate.convert(price_eur, currency)
    return nil unless converted

    "(~#{format_converted_price(converted)} #{currency})"
  end

  def format_converted_price(amount)
    amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end
end
