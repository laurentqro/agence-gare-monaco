class PropertiesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access
  before_action :initialize_information_request

  def index
    @transaction_type = params[:transaction_type]

    @properties = Property.publicly_visible
    @properties = @properties.where(transaction_type: @transaction_type) if @transaction_type.present?

    district_param = I18n.t("listings.filter_param_district", default: "district")
    if params[district_param].present?
      district_slugs = Array(params[district_param])
      districts = District.where(slug: district_slugs)
      @properties = @properties.where(district: districts) if districts.any?
    end

    type_param = I18n.t("listings.filter_param_type", default: "type")
    if params[type_param].present?
      localized_values = Array(params[type_param])
      @properties = apply_type_filters(@properties, localized_values)
    end
    @properties = @properties.includes(:property_images, :district).order(created_at: :desc)

    @districts = District.where(city: "Monaco").order(:name)

    compute_filter_counts

    set_seo(page_type: :listings, transaction_type: @transaction_type)
  end

  def show
    @property = Property.published.includes(:district, :building, :property_images, property_documents: { file_attachment: :blob }).find(params[:id])
    @photos = @property.photos
    @plans = @property.plans
    @documents = @property.property_documents.select { |d| d.file.attached? }

    unless @property.off_market?
      @similar_properties = Property.publicly_visible
        .where(transaction_type: @property.transaction_type)
        .where.not(id: @property.id)
      @similar_properties = @similar_properties.where(district: @property.district) if @property.district.present?
      @similar_properties = @similar_properties.includes(:property_images, :district).limit(3)
    end

    set_seo(page_type: :property, property: @property)
  end

  def off_market
    @sales = Property.published.where(off_market: true).for_sale
      .includes(:property_images, :district).order(created_at: :desc)
    @rentals = Property.published.where(off_market: true).for_rental
      .includes(:property_images, :district).order(created_at: :desc)
    set_seo(page_type: :offmarket)
  end

  def pdf
    @property = Property.published.includes(:district, :building, :property_images).find(params[:id])
    locale = params[:locale]&.to_sym || I18n.locale
    include_logo = params[:include_logo] != "0"

    pdf_bytes = PropertyBrochureCache.fetch(@property, locale: locale, include_logo: include_logo)
    send_data pdf_bytes, filename: @property.brochure_filename, type: "application/pdf", disposition: :attachment
  end

  private

  def initialize_information_request
    @submission = InformationRequest.new
  end

  def apply_type_filters(scope, localized_values)
    canonical_keys = localized_values.map { |lv| canonical_type_filter_key(lv) }
    filter_defs = ApplicationHelper::TYPE_FILTER_GROUPS.flatten(1)

    conditions = canonical_keys.filter_map do |key|
      defn = filter_defs.find { |k, _, _| k == key }
      next unless defn
      _, property_type, rooms = defn
      if rooms == :gt5
        scope.where(property_type: property_type).where("num_rooms > 5")
      elsif rooms
        scope.where(property_type: property_type, num_rooms: rooms)
      else
        scope.where(property_type: property_type)
      end
    end

    return scope.none if conditions.empty?

    # OR all conditions together
    combined = conditions.reduce { |result, cond| result.or(cond) }
    combined
  end

  def compute_filter_counts
    # Base query: transaction type + visibility (before any type/district filters)
    base = Property.publicly_visible
    base = base.where(transaction_type: @transaction_type) if @transaction_type.present?

    # For type counts, apply district filter (so counts reflect cross-filter)
    type_count_base = base
    district_param = I18n.t("listings.filter_param_district", default: "district")
    if params[district_param].present?
      district_slugs = Array(params[district_param])
      districts = District.where(slug: district_slugs)
      type_count_base = type_count_base.where(district: districts) if districts.any?
    end

    # For district counts, apply type filter (so counts reflect cross-filter)
    district_count_base = base
    type_param = I18n.t("listings.filter_param_type", default: "type")
    if params[type_param].present?
      localized_values = Array(params[type_param])
      district_count_base = apply_type_filters(district_count_base, localized_values)
    end

    # Compute type filter counts
    @type_filter_counts = {}
    filter_defs = ApplicationHelper::TYPE_FILTER_GROUPS.flatten(1)
    filter_defs.each do |key, property_type, rooms|
      count = if rooms == :gt5
        type_count_base.where(property_type: property_type).where("num_rooms > 5").count
      elsif rooms
        type_count_base.where(property_type: property_type, num_rooms: rooms).count
      else
        type_count_base.where(property_type: property_type).count
      end
      @type_filter_counts[key] = count
    end

    # Compute district counts
    @district_filter_counts = {}
    district_counts = district_count_base.where(district: @districts).group(:district_id).count
    @districts&.each do |district|
      @district_filter_counts[district.slug] = district_counts[district.id] || 0
    end
  end

  def canonical_type_filter_key(localized_value)
    translations = I18n.t("listings.type_filters", default: {})
    translations.each do |canonical, translated|
      return canonical.to_s if translated.downcase == localized_value.downcase
    end
    localized_value
  end
end
