class SitemapsController < ApplicationController
  include SeoHelper
  include ApplicationHelper
  allow_unauthenticated_access

  def index
    respond_to do |format|
      format.xml
    end
  end

  def show
    @locale = params[:locale]&.to_sym
    unless I18n.available_locales.include?(@locale)
      head :not_found
      return
    end

    @properties = Property.publicly_visible.includes(:district, :property_images).order(:id)
    @articles = Article.published.order(:id)

    respond_to do |format|
      format.xml
    end
  end
end
