# Hedonic price-per-m² estimator based on IMSEE's Observatoire de l'Immobilier
# 2025 (Annexe 1) regression. Coefficients are in €/m². Adjusted R² = 0.51 —
# the remaining 49% of variance reflects unmodeled features (floor, view,
# condition), so callers should treat estimates as a band, not a point.
class PropertyValuator
  class UnknownDistrictError < StandardError; end

  CONSTANT = 23_156

  DISTRICT_COEFFICIENTS = {
    "monte-carlo"     => 0,
    "larvotto"        => 10_716,
    "la-condamine"    => -1_002,
    "fontvieille"     => -5_619,
    "la-rousse"       => -6_317,
    "les-moneghetti"  => -10_328,
    "jardin-exotique" => -12_726
  }.freeze

  DISTRICT_NAMES = {
    "monte-carlo"     => "Monte-Carlo",
    "larvotto"        => "Larvotto",
    "la-condamine"    => "La Condamine",
    "fontvieille"     => "Fontvieille",
    "la-rousse"       => "La Rousse",
    "les-moneghetti"  => "Les Moneghetti",
    "jardin-exotique" => "Jardin Exotique"
  }.freeze

  YEAR_COEFFICIENTS = {
    2011 => 0,     2012 => 0,     2013 => 0,
    2014 => 5_265, 2015 => 7_881, 2016 => 10_887,
    2017 => 12_552, 2018 => 15_781, 2019 => 17_012,
    2020 => 17_667, 2021 => 17_936, 2022 => 19_424,
    2023 => 19_155, 2024 => 20_536, 2025 => 22_124
  }.freeze
  LATEST_YEAR = 2025

  CONSTRUCTION_PERIODS = [
    { range: 1880..1939, coefficient: 0 },
    { range: 1940..1959, coefficient: 4_653 },
    { range: 1960..1969, coefficient: 12_142 },
    { range: 1970..1979, coefficient: 10_372 },
    { range: 1980..1989, coefficient: 12_104 },
    { range: 1990..1999, coefficient: 10_013 },
    { range: 2000..2009, coefficient: 23_701 },
    { range: 2010..2019, coefficient: 17_399 },
    { range: 2020..2029, coefficient: 15_246 }
  ].freeze

  CONFIDENCE_BAND = 0.25

  def self.estimate(**args)
    new(**args).estimate
  end

  def initialize(district:, surface:, construction_year:, transaction_year:)
    @district_slug = district.is_a?(District) ? district.slug : district.to_s
    @surface = surface
    @construction_year = construction_year.to_i
    @transaction_year = [transaction_year.to_i, LATEST_YEAR].min
    validate!
  end

  def estimate
    price_per_m2 = CONSTANT + district_coefficient + year_coefficient + period_coefficient
    total = (price_per_m2 * @surface).round

    {
      price_per_m2: price_per_m2,
      total_estimate: total,
      low_estimate: (total * (1 - CONFIDENCE_BAND)).round,
      high_estimate: (total * (1 + CONFIDENCE_BAND)).round,
      inputs: {
        district: @district_slug,
        surface: @surface,
        construction_year: @construction_year,
        transaction_year: @transaction_year
      }
    }
  end

  private

  def validate!
    raise ArgumentError, "surface must be positive" unless @surface.is_a?(Numeric) && @surface > 0
    raise ArgumentError, "construction_year must be ≥ 1880" if @construction_year < 1880
    raise ArgumentError, "transaction_year must be ≥ 2011" if @transaction_year < 2011

    unless DISTRICT_COEFFICIENTS.key?(@district_slug)
      raise UnknownDistrictError, "no IMSEE coefficient for district: #{@district_slug.inspect}"
    end
  end

  def district_coefficient
    DISTRICT_COEFFICIENTS.fetch(@district_slug)
  end

  def year_coefficient
    YEAR_COEFFICIENTS.fetch(@transaction_year, YEAR_COEFFICIENTS[LATEST_YEAR])
  end

  def period_coefficient
    period = CONSTRUCTION_PERIODS.find { |p| p[:range].cover?(@construction_year) }
    period ? period[:coefficient] : CONSTRUCTION_PERIODS.last[:coefficient]
  end
end
