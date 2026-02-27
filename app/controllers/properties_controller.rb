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
    @property = Property.find(params[:id])
  end
end
