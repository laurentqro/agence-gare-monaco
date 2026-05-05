class EstimatesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def new
    @form = blank_form
    set_seo(page_type: :estimate)
  end

  def create
    @form = {
      district: params[:district].to_s,
      surface: params[:surface],
      construction_year: params[:construction_year]
    }
    set_seo(page_type: :estimate)

    surface = parse_positive(params[:surface])
    year    = parse_positive(params[:construction_year])

    if surface.nil?
      @errors = [ t("estimate.errors.surface_required") ]
      return render :new, status: :unprocessable_content
    end

    if year.nil? || year < 1880 || year > Date.current.year
      @errors = [ t("estimate.errors.construction_year_required", year: Date.current.year) ]
      return render :new, status: :unprocessable_content
    end

    @result = PropertyValuator.estimate(
      district: @form[:district],
      surface: surface,
      construction_year: year,
      transaction_year: Date.current.year
    )
    render :new
  rescue PropertyValuator::UnknownDistrictError
    @errors = [ t("estimate.errors.district_unavailable") ]
    render :new, status: :unprocessable_content
  rescue ArgumentError
    @errors = [ t("estimate.errors.invalid") ]
    render :new, status: :unprocessable_content
  end

  private

  def blank_form
    { district: "", surface: "", construction_year: "" }
  end

  def parse_positive(value)
    return nil if value.blank?
    n = Float(value, exception: false)
    return nil if n.nil? || n <= 0
    n.to_i
  end
end
