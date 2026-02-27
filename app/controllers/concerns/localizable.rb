module Localizable
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    locale = params[:locale]&.to_sym
    if I18n.available_locales.include?(locale)
      I18n.with_locale(locale, &action)
    else
      raise ActionController::RoutingError, "Locale not found: #{locale}"
    end
  end

  def default_url_options
    { locale: I18n.locale }
  end
end
