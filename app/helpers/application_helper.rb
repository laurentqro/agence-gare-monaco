module ApplicationHelper
  def locale_root_path(locale = I18n.locale)
    locale.to_sym == :fr ? "/" : "/#{locale}"
  end

  def locale_prefix(locale = I18n.locale)
    locale.to_sym == :fr ? "" : "/#{locale}"
  end

  def locale_sales_path(locale = I18n.locale)
    sales = I18n.t("routes.sales", locale: locale)
    "#{locale_prefix(locale)}/#{sales}"
  end

  def locale_rentals_path(locale = I18n.locale)
    rentals = I18n.t("routes.rentals", locale: locale)
    "#{locale_prefix(locale)}/#{rentals}"
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

  def locale_offmarket_path(locale = I18n.locale)
    offmarket = I18n.t("routes.offmarket", locale: locale)
    "#{locale_prefix(locale)}/#{offmarket}"
  end

  def locale_gestion_path(locale = I18n.locale)
    gestion = I18n.t("routes.gestion", locale: locale)
    "#{locale_prefix(locale)}/#{gestion}"
  end

  def locale_vendre_path(locale = I18n.locale)
    vendre = I18n.t("routes.vendre", locale: locale)
    "#{locale_prefix(locale)}/#{vendre}"
  end

  def locale_faq_path(locale = I18n.locale)
    faq = I18n.t("routes.faq", locale: locale)
    "#{locale_prefix(locale)}/#{faq}"
  end

  def locale_estimate_path(locale = I18n.locale)
    estimate = I18n.t("routes.estimate", locale: locale)
    "#{locale_prefix(locale)}/#{estimate}"
  end

  def locale_team_member_path(member_slug, locale = I18n.locale)
    team = I18n.t("routes.team", locale: locale)
    "#{locale_prefix(locale)}/#{team}/#{member_slug}"
  end

  def switch_locale_path(locale)
    controller_name = params[:controller]
    action_name = params[:action]

    case "#{controller_name}##{action_name}"
    when "pages#home"
      locale_root_path(locale)
    when "properties#index"
      switch_locale_listings_path(locale)
    when "properties#show"
      locale_property_path_for_switch(locale)
    when "properties#off_market"
      locale_offmarket_path(locale)
    when "articles#index"
      locale_articles_path(locale)
    when "articles#show"
      switch_locale_article_path(locale)
    when "pages#contact"
      locale_contact_path(locale)
    when "pages#privacy"
      locale_privacy_path(locale)
    when "pages#gestion"
      locale_gestion_path(locale)
    when "pages#vendre"
      locale_vendre_path(locale)
    when "pages#faq"
      locale_faq_path(locale)
    when "pages#team_member"
      locale_team_member_path(params[:member], locale)
    when "estimates#new", "estimates#create"
      locale_estimate_path(locale)
    else
      locale_root_path(locale)
    end
  end

  LOCALE_FLAGS = {
    fr: "fr", en: "gb", it: "it", de: "de",
    sv: "se", no: "no", da: "dk", fi: "fi", ru: "ru"
  }.freeze

  LOCALE_NAMES = {
    fr: "Français", en: "English", it: "Italiano", de: "Deutsch",
    sv: "Svenska", no: "Norsk", da: "Dansk", fi: "Suomi", ru: "Русский"
  }.freeze

  def locale_property_path(property, locale = I18n.locale)
    props = I18n.t("routes.properties", locale: locale)
    slug = property.title_for(locale).parameterize
    "#{locale_prefix(locale)}/#{props}/#{property.id}-#{slug}"
  end

  def listing_heading
    transaction = params[:transaction_type]

    if transaction == "sale"
      t("listings.sales")
    elsif transaction == "rental"
      t("listings.rentals")
    else
      t("listings.sales")
    end
  end

  # Each filter option: [key, property_type, num_rooms_condition]
  # key is used in the URL, property_type/num_rooms used for DB query
  TYPE_FILTER_GROUPS = [
    # Residential by room count
    [
      [ "studio",   "apartment", 1 ],
      [ "2-pieces", "apartment", 2 ],
      [ "3-pieces", "apartment", 3 ],
      [ "4-pieces", "apartment", 4 ],
      [ "5-pieces", "apartment", 5 ],
      [ "5-pieces-plus", "apartment", :gt5 ]
    ],
    # Premium
    [
      [ "penthouse", "penthouse", nil ],
      [ "duplex",    "duplex",    nil ]
    ],
    # Commercial
    [
      [ "office",     "office",     nil ],
      [ "commercial", "commercial", nil ],
      [ "local",      "local",      nil ],
      [ "parking",    "parking",    nil ],
      [ "cave",       "cave",       nil ]
    ]
  ].freeze

  # Returns filter groups with translated labels
  def grouped_type_filter_options
    TYPE_FILTER_GROUPS.filter_map do |group|
      options = group.filter_map do |key, type, rooms|
        label = I18n.t("listings.type_filters.#{key}", default: key.capitalize)
        localized_key = label.downcase
        [ localized_key, key, label ]
      end
      options.presence
    end
  end

  def url_without_param(*param_names)
    filtered = request.query_parameters.except(*param_names.map(&:to_s))
    filtered.any? ? "#{request.path}?#{filtered.to_query}" : request.path
  end

  def url_without_filter_value(param_name, value)
    qp = request.query_parameters.deep_dup
    key = localized_filter_param(param_name)
    current = Array(qp[key])
    remaining = current - [ value.to_s ]
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
      # value is already the localized label (lowercase) — titlecase it
      value.split.map(&:capitalize).join(" ")
    when "district"
      District.find_by(slug: value)&.name || value
    end
  end

  # Returns the localized query param name for a canonical filter (e.g. "type" -> "tipo" in Italian)
  def localized_filter_param(canonical)
    I18n.t("listings.filter_param_#{canonical}", default: canonical.to_s)
  end

  # Reads filter values from the localized query param name
  def filter_values_for(canonical)
    Array(params[localized_filter_param(canonical)])
  end

  def flag_image_for(locale)
    LOCALE_FLAGS[locale.to_sym] || locale.to_s
  end

  def locale_name_for(locale)
    LOCALE_NAMES[locale.to_sym] || locale.to_s
  end

  def whatsapp_property_message(property, property_url)
    # FR and RU use their own locale for WhatsApp text; all others use English
    wa_locale = %i[fr ru].include?(I18n.locale) ? I18n.locale : :en

    area_val = property.living_area
    area_str = area_val ? (area_val.to_i == area_val ? area_val.to_i.to_s : area_val.to_s) : nil
    transaction = property.transaction_type == "sale" ? I18n.t("contact_form.whatsapp_for_sale", locale: wa_locale) : I18n.t("contact_form.whatsapp_for_rent", locale: wa_locale)
    building_part = property.building ? " #{I18n.t('contact_form.whatsapp_in_building', building: property.building.name, locale: wa_locale)}" : ""

    description = if wa_locale == :en
      rooms = property.num_rooms ? "#{property.num_rooms}-bedroom" : nil
      area = area_str ? "#{area_str}m²" : nil
      parts = [ area, rooms, I18n.t("contact_form.whatsapp_property_type.#{property.property_type}", default: "property", locale: :en) ].compact
      "#{parts.join(' ')} #{transaction}#{building_part}"
    else
      rooms = I18n.t("contact_form.whatsapp_rooms", count: property.num_rooms || 0, locale: wa_locale)
      area = area_str ? " #{I18n.t('contact_form.whatsapp_of_area', area: area_str, locale: wa_locale)}" : ""
      "#{rooms}#{area} #{transaction}#{building_part}"
    end

    I18n.t("contact_form.whatsapp_enquiry_message", description: description, url: property_url, locale: wa_locale)
  end

  def nav_active_class(nav_path)
    request.path.start_with?(nav_path) ? "nav-active" : ""
  end

  private

  def switch_locale_listings_path(locale)
    transaction = params[:transaction_type]
    transaction == "sale" ? locale_sales_path(locale) : locale_rentals_path(locale)
  end

  def locale_property_path_for_switch(locale)
    property = @property || Property.find(params[:id].to_i)
    locale_property_path(property, locale)
  end

  def switch_locale_article_path(locale)
    slug = params[:slug]
    articles_segment = I18n.t("routes.articles", locale: locale)
    "#{locale_prefix(locale)}/#{articles_segment}/#{slug}"
  end
end
