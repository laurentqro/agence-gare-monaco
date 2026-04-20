module Admin
  class PropertyBrochuresController < BaseController
    before_action :set_property

    def new
    end

    def create
      locale = (params[:locale].presence || "fr").to_sym
      include_logo = params[:include_logo] != "0"

      pdf_bytes = PropertyBrochureCache.fetch(@property, locale: locale, include_logo: include_logo)
      send_data pdf_bytes, filename: @property.brochure_filename, type: "application/pdf", disposition: :attachment
    end

    private

    def set_property
      @property = Property.find(params[:property_id])
    end
  end
end
