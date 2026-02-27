module ApplicationHelper
  def locale_root_path(locale = I18n.locale)
    "/#{locale}"
  end

  def locale_sales_monaco_path(locale = I18n.locale)
    sales = I18n.t("routes.sales", locale: locale)
    "/#{locale}/#{sales}/monaco"
  end

  def locale_rentals_monaco_path(locale = I18n.locale)
    rentals = I18n.t("routes.rentals", locale: locale)
    "/#{locale}/#{rentals}/monaco"
  end

  def locale_sales_france_path(locale = I18n.locale)
    sales = I18n.t("routes.sales", locale: locale)
    france = I18n.t("routes.france", locale: locale)
    "/#{locale}/#{sales}/#{france}"
  end

  def locale_articles_path(locale = I18n.locale)
    articles = I18n.t("routes.articles", locale: locale)
    "/#{locale}/#{articles}"
  end

  def locale_contact_path(locale = I18n.locale)
    contact = I18n.t("routes.contact", locale: locale)
    "/#{locale}/#{contact}"
  end

  def locale_privacy_path(locale = I18n.locale)
    privacy = I18n.t("routes.privacy", locale: locale)
    "/#{locale}/#{privacy}"
  end

  def switch_locale_path(locale)
    locale_root_path(locale)
  end

  LOCALE_FLAGS = {
    fr: "fr", en: "gb", it: "it", de: "de",
    sv: "se", no: "no", da: "dk", fi: "fi"
  }.freeze

  LOCALE_NAMES = {
    fr: "Français", en: "English", it: "Italiano", de: "Deutsch",
    sv: "Svenska", no: "Norsk", da: "Dansk", fi: "Suomi"
  }.freeze

  def flag_image_for(locale)
    LOCALE_FLAGS[locale.to_sym] || locale.to_s
  end

  def locale_name_for(locale)
    LOCALE_NAMES[locale.to_sym] || locale.to_s
  end
end
