class PropertiesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access
  before_action :initialize_contact_submission

  def index
    @transaction_type = params[:transaction_type]
    @country = params[:country]

    @properties = Property.publicly_visible
    @properties = @properties.where(transaction_type: @transaction_type) if @transaction_type.present?
    @properties = @properties.in_country(@country) if @country.present?

    if params[:district_slug].present?
      @district = District.find_by!(slug: params[:district_slug])
      @properties = @properties.in_district(@district)
    end

    @properties = @properties.of_type(params[:type]) if params[:type].present?
    @properties = @properties.includes(:property_images, :district).order(created_at: :desc)

    @districts = District.where(city: "Monaco").order(:name) if @country == "MC"

    set_seo(page_type: :listings, transaction_type: @transaction_type, country: @country, district: @district)
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

  private

  def initialize_contact_submission
    @submission = ContactSubmission.new
  end
end
