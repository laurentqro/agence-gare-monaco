module Admin
  class PropertiesController < BaseController
    before_action :set_property, only: %i[edit update destroy]
    before_action :set_form_data, only: %i[new create edit update]

    def index
      @properties = Property.includes(:district, :building).order(created_at: :desc)
    end

    def new
      @property = Property.new
    end

    def create
      @property = Property.new(property_params)
      if @property.save
        redirect_to admin_properties_url, notice: "Property created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @property.assign_attributes(property_params)
      mark_manually_edited if @property.immotoolbox_id.present?
      if @property.save
        redirect_to admin_properties_url, notice: "Property updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to admin_properties_url, notice: "Property deleted."
    end

    private

    def set_property
      @property = Property.find(params[:id])
    end

    def set_form_data
      @districts = District.order(:name)
      @buildings = Building.order(:name)
    end

    def property_params
      params.require(:property).permit(
        :reference, :price, :currency, :service_charges, :service_charges_included,
        :transaction_type, :property_type, :subtype,
        :country, :city, :address, :district_id, :building_id,
        :latitude, :longitude, :floor,
        :num_rooms, :num_bedrooms, :num_bathrooms, :num_parkings, :num_cellars,
        :living_area, :total_area, :terrace_area, :land_area, :garden_area,
        :furnished, :published, :off_market, :featured, :exclusivity, :shared_exclusivity,
        :video_url, :virtual_tour_url, :has_360_tour,
        title: I18n.available_locales.map(&:to_s),
        description: I18n.available_locales.map(&:to_s)
      )
    end

    def mark_manually_edited
      @property.manually_edited = true
    end
  end
end
