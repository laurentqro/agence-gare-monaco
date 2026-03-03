module Admin
  class PropertyBrochuresController < BaseController
    before_action :set_property

    def new
    end

    def create
      locale = (params[:locale].presence || "fr").to_sym
      include_logo = params[:include_logo] != "0"

      pdf_bytes = PropertyPdfGenerator.new(@property, locale: locale, include_logo: include_logo).generate

      filename = "#{@property.reference}-#{locale}.pdf"
      send_data pdf_bytes, filename: filename, type: "application/pdf", disposition: :attachment
    end

    private

    def set_property
      @property = Property.find(params[:property_id])
    end
  end
end
