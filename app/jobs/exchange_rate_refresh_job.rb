class ExchangeRateRefreshJob < ApplicationJob
  queue_as :default

  def perform
    CurrencyConverter.refresh
  end
end
