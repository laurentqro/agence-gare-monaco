class PropertiesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

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
  end

  def show
    @property = Property.includes(:district, :building, :property_images).find(params[:id])
    @photos = @property.photos
    @plans = @property.plans

    @similar_properties = Property.publicly_visible
      .where(transaction_type: @property.transaction_type)
      .where.not(id: @property.id)
    @similar_properties = @similar_properties.where(district: @property.district) if @property.district.present?
    @similar_properties = @similar_properties.includes(:property_images, :district).limit(3)
  end
end
