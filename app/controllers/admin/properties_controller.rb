module Admin
  class PropertiesController < BaseController
    before_action :set_property, only: %i[show edit update destroy]
    before_action :block_synced_edits!, only: %i[edit update destroy]
    before_action :set_form_data, only: %i[new create edit update]

    def index
      @properties = Property.includes(:district, :building).order(created_at: :desc)
      @properties = @properties.where(off_market: true) if params[:filter] == "off_market"
    end

    def show
    end

    def new
      @property = Property.new
    end

    def create
      @property = Property.new(property_params)
      @property.off_market = true
      if @property.save
        @property.enqueue_post_save_jobs!
        redirect_to admin_properties_url, notice: t("admin.properties.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @property.assign_attributes(property_params)
      @property.off_market = true
      if @property.save
        @property.enqueue_post_save_jobs!
        redirect_to admin_properties_url, notice: t("admin.properties.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @property.destroy
      redirect_to admin_properties_url, notice: t("admin.properties.flash.deleted")
    end

    private

    def set_property
      @property = Property.find(params[:id])
    end

    def block_synced_edits!
      raise ActiveRecord::RecordNotFound, "Synced properties are read-only" if @property.immotoolbox_id.present?
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
        :furnished, :published, :featured, :exclusivity, :shared_exclusivity,
        :video_url, :virtual_tour_url, :has_360_tour,
        title: [ "fr" ],
        description: [ "fr" ]
      )
    end

  end
end
