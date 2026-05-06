class EstimatesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  # Even Monaco's largest single-floor properties are well under this — the
  # bound exists to reject `1e10`-style adversarial inputs before they reach
  # the layout (which can't render trillion-euro numbers gracefully).
  MAX_SURFACE_M2 = 100_000

  # Single GET endpoint so the result URL is shareable.
  # Query keys are localized (e.g. /estimer?quartier=...&surface=...&annee-construction=...
  # in FR, /en/valuation?district=...&area=...&construction-year=... in EN), but English
  # keys are accepted as a fallback so older shared URLs and the language switcher's
  # cross-locale rewrites both work.
  def new
    district = read_param(:district)
    surface_raw = read_param(:surface)
    year_raw = read_param(:construction_year)

    @form = {
      district: district.to_s,
      surface: surface_raw,
      construction_year: year_raw
    }
    set_seo(page_type: :estimate)

    return if @form.values.any?(&:blank?)

    surface = parse_positive(surface_raw)
    year    = parse_positive(year_raw)

    if surface.nil? || surface < 1 || surface > MAX_SURFACE_M2
      @errors = [ t("estimate.errors.surface_required", max: MAX_SURFACE_M2) ]
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
    # The bare landing page (no result) is the canonical FAQ resource — don't
    # duplicate the FAQPage JSON-LD on result URLs.
    set_seo(page_type: :estimate, with_faq: false)
  rescue PropertyValuator::UnknownDistrictError
    @errors = [ t("estimate.errors.district_unavailable") ]
    render :new, status: :unprocessable_content
  rescue ArgumentError
    @errors = [ t("estimate.errors.invalid") ]
    render :new, status: :unprocessable_content
  end

  private

  # Read a canonical estimate input under its locale-localized query key, falling back
  # to the English key (district/surface/construction_year) so legacy URLs keep working.
  def read_param(canonical)
    localized_key = I18n.t("estimate.param.#{canonical}", default: canonical.to_s)
    params[localized_key].presence || params[canonical]
  end

  def parse_positive(value)
    return nil if value.blank?
    n = Float(value, exception: false)
    return nil if n.nil? || n <= 0
    n.to_i
  end
end
