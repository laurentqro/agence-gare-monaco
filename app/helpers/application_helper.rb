module ApplicationHelper
  def locale_root_path(locale = I18n.locale)
    locale.to_sym == :fr ? "/" : "/#{locale}"
  end

  def locale_prefix(locale = I18n.locale)
    locale.to_sym == :fr ? "" : "/#{locale}"
  end

  def locale_sales_monaco_path(locale = I18n.locale)
    sales = I18n.t("routes.sales", locale: locale)
    "#{locale_prefix(locale)}/#{sales}/monaco"
  end

  def locale_rentals_monaco_path(locale = I18n.locale)
    rentals = I18n.t("routes.rentals", locale: locale)
    "#{locale_prefix(locale)}/#{rentals}/monaco"
  end

  def locale_sales_france_path(locale = I18n.locale)
    sales = I18n.t("routes.sales", locale: locale)
    france = I18n.t("routes.france", locale: locale)
    "#{locale_prefix(locale)}/#{sales}/#{france}"
  end

  def locale_articles_path(locale = I18n.locale)
    articles = I18n.t("routes.articles", locale: locale)
    "#{locale_prefix(locale)}/#{articles}"
  end

  def locale_contact_path(locale = I18n.locale)
    contact = I18n.t("routes.contact", locale: locale)
    "#{locale_prefix(locale)}/#{contact}"
  end

  def locale_privacy_path(locale = I18n.locale)
    privacy = I18n.t("routes.privacy", locale: locale)
    "#{locale_prefix(locale)}/#{privacy}"
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

  def locale_property_path(property, locale = I18n.locale)
    props = I18n.t("routes.properties", locale: locale)
    slug = property.title_for(locale).parameterize
    "#{locale_prefix(locale)}/#{props}/#{property.id}-#{slug}"
  end

  def listing_heading
    transaction = params[:transaction_type]
    country = params[:country]
    district = @district if defined?(@district)

    if district
      key = transaction == "sale" ? "listings.sales_in_district" : "listings.rentals_in_district"
      t(key, district: district.name)
    elsif country == "MC" && transaction == "sale"
      t("listings.sales_monaco")
    elsif country == "MC" && transaction == "rental"
      t("listings.rentals_monaco")
    elsif country == "FR"
      t("listings.sales_france")
    elsif transaction == "sale"
      t("listings.sales")
    elsif transaction == "rental"
      t("listings.rentals")
    else
      t("listings.sales")
    end
  end

  def property_type_options
    Property.publicly_visible.distinct.pluck(:property_type).compact.sort
  end

  def url_without_param(*param_names)
    filtered = request.query_parameters.except(*param_names.map(&:to_s))
    filtered.any? ? "#{request.path}?#{filtered.to_query}" : request.path
  end

  def url_without_filter_value(param_name, value)
    qp = request.query_parameters.deep_dup
    key = param_name.to_s
    current = Array(qp[key])
    remaining = current - [value.to_s]
    if remaining.any?
      qp[key] = remaining
    else
      qp.delete(key)
    end
    qp.any? ? "#{request.path}?#{qp.to_query}" : request.path
  end

  def filter_chip_label(param_name, value)
    case param_name.to_s
    when "type"
      translated_property_type(value)
    when "district"
      District.find_by(slug: value)&.name || value
    end
  end

  def translated_property_type(type)
    I18n.t("listings.property_types.#{type}", default: type.capitalize)
  end

  def flag_image_for(locale)
    LOCALE_FLAGS[locale.to_sym] || locale.to_s
  end

  def locale_name_for(locale)
    LOCALE_NAMES[locale.to_sym] || locale.to_s
  end
end
