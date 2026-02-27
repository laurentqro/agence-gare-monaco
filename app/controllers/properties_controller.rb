class PropertiesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

  def index
    if params[:district_slug].present?
      @district = District.find_by!(slug: params[:district_slug])
    end
  end

  def show
    @property = Property.find(params[:id])
  end
end
