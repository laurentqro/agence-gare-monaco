class ExchangeRate < ApplicationRecord
  validates :currency, presence: true, uniqueness: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :fetched_at, presence: true

  LOCALE_CURRENCIES = {
    fr: "EUR", en: "GBP", it: "EUR", de: "EUR",
    sv: "SEK", no: "NOK", da: "DKK", fi: "EUR"
  }.freeze

  def self.locale_currency(locale)
    LOCALE_CURRENCIES[locale.to_sym] || "EUR"
  end

  def self.convert(amount_eur, target_currency)
    return nil if amount_eur.blank? || target_currency == "EUR"

    rate_record = find_by(currency: target_currency)
    return nil unless rate_record

    (amount_eur * rate_record.rate).round
  end
end
