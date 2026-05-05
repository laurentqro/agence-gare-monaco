require "test_helper"

class PropertyValuatorTest < ActiveSupport::TestCase
  test "reproduces IMSEE worked example for Monte-Carlo 2025 2020s building" do
    result = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    assert_equal 60_526, result[:price_per_m2]
    assert_equal 6_052_600, result[:total_estimate]
  end

  test "applies Larvotto premium" do
    result = PropertyValuator.estimate(
      district: "larvotto",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    expected = 23_156 + 22_124 + 10_716 + 15_246
    assert_equal expected, result[:price_per_m2]
  end

  test "applies Jardin Exotique discount" do
    result = PropertyValuator.estimate(
      district: "jardin-exotique",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    expected = 23_156 + 22_124 + (-12_726) + 15_246
    assert_equal expected, result[:price_per_m2]
  end

  test "uses 2011-2013 reference year (zero coefficient)" do
    result = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2012
    )

    expected = 23_156 + 0 + 0 + 15_246
    assert_equal expected, result[:price_per_m2]
  end

  test "uses 1880-1939 reference construction period (zero coefficient)" do
    result = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 1920,
      transaction_year: 2025
    )

    expected = 23_156 + 22_124 + 0 + 0
    assert_equal expected, result[:price_per_m2]
  end

  test "1960s building gets +12 142 coefficient" do
    result = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 1965,
      transaction_year: 2025
    )

    expected = 23_156 + 22_124 + 0 + 12_142
    assert_equal expected, result[:price_per_m2]
  end

  test "La Condamine coefficient applied even though not statistically significant" do
    result = PropertyValuator.estimate(
      district: "la-condamine",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    expected = 23_156 + 22_124 + (-1_002) + 15_246
    assert_equal expected, result[:price_per_m2]
  end

  test "returns ±25% confidence band reflecting unexplained variance" do
    result = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    assert_equal (6_052_600 * 0.75).round, result[:low_estimate]
    assert_equal (6_052_600 * 1.25).round, result[:high_estimate]
  end

  test "echoes inputs in result" do
    result = PropertyValuator.estimate(
      district: "larvotto",
      surface: 120,
      construction_year: 2024,
      transaction_year: 2025
    )

    assert_equal "larvotto", result[:inputs][:district]
    assert_equal 120, result[:inputs][:surface]
    assert_equal 2024, result[:inputs][:construction_year]
    assert_equal 2025, result[:inputs][:transaction_year]
  end

  test "accepts District record as district argument" do
    district = districts(:monte_carlo) if District.respond_to?(:fixtures) && false
    district = District.find_or_create_by!(slug: "monte-carlo") do |d|
      d.name = "Monte-Carlo"
      d.city = "Monaco"
    end

    result = PropertyValuator.estimate(
      district: district,
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    assert_equal 60_526, result[:price_per_m2]
  end

  test "raises on unknown district" do
    assert_raises(PropertyValuator::UnknownDistrictError) do
      PropertyValuator.estimate(
        district: "monaco-ville",
        surface: 100,
        construction_year: 2024,
        transaction_year: 2025
      )
    end
  end

  test "raises on non-positive surface" do
    assert_raises(ArgumentError) do
      PropertyValuator.estimate(
        district: "monte-carlo",
        surface: 0,
        construction_year: 2024,
        transaction_year: 2025
      )
    end
  end

  test "raises on construction year before 1880" do
    assert_raises(ArgumentError) do
      PropertyValuator.estimate(
        district: "monte-carlo",
        surface: 100,
        construction_year: 1850,
        transaction_year: 2025
      )
    end
  end

  test "raises on transaction year before 2011" do
    assert_raises(ArgumentError) do
      PropertyValuator.estimate(
        district: "monte-carlo",
        surface: 100,
        construction_year: 2024,
        transaction_year: 2010
      )
    end
  end

  test "clamps transaction year above 2025 to 2025 coefficient" do
    future = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2030
    )

    current = PropertyValuator.estimate(
      district: "monte-carlo",
      surface: 100,
      construction_year: 2024,
      transaction_year: 2025
    )

    assert_equal current[:price_per_m2], future[:price_per_m2]
  end
end
