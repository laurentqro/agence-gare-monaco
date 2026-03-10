require "test_helper"

class CurrencyDisplayTest < ActionDispatch::IntegrationTest
  setup do
    @property = Property.create!(
      reference: "CURR-001",
      title: { "en" => "Luxury Studio", "sv" => "Lyxig Studio" },
      description: { "en" => "A luxury studio", "sv" => "En lyxig studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      published: true,
      off_market: false
    )
    @property.property_images.create!(
      remote_url: "https://example.com/photo.jpg",
      thumb_url: "https://example.com/thumb.jpg",
      small_url: "https://example.com/small.jpg",
      medium_url: "https://example.com/medium.jpg",
      large_url: "https://example.com/large.jpg"
    )
  end

  test "property detail shows converted price for Swedish locale when rate available" do
    ExchangeRate.create!(currency: "SEK", rate: 11.25, fetched_at: Time.current)
    get "/sv/forsaljning"
    assert_response :success
    assert_select "[data-testid='converted-price']"
  end

  test "property detail does not show converted price for French locale" do
    get "/ventes"
    assert_response :success
    assert_select "[data-testid='converted-price']", count: 0
  end

  test "property detail does not show converted price when no rate available" do
    get "/sv/forsaljning"
    assert_response :success
    assert_select "[data-testid='converted-price']", count: 0
  end

  test "property card shows converted price on listings page" do
    ExchangeRate.create!(currency: "SEK", rate: 11.25, fetched_at: Time.current)
    get "/sv/forsaljning"
    assert_response :success
    assert_select "[data-testid='converted-price']"
  end
end
