require "test_helper"

class PropertyPdfDownloadTest < ActionDispatch::IntegrationTest
  setup do
    @property = Property.create!(
      reference: "MC-PDF-DL",
      title: { "fr" => "Studio Carré d'Or", "en" => "Sea view studio" },
      description: { "fr" => "Magnifique studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      published: true
    )
  end

  # French (default locale, no prefix)
  test "GET pdf returns PDF for French locale" do
    get "/biens/#{@property.id}-studio-carre-dor/pdf"
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "GET pdf returns attachment disposition with reference" do
    get "/biens/#{@property.id}-studio-carre-dor/pdf"
    assert_match /attachment/, response.headers["Content-Disposition"]
    assert_match /MC-PDF-DL/, response.headers["Content-Disposition"]
  end

  # English locale
  test "GET pdf returns PDF for English locale" do
    get "/en/properties/#{@property.id}-sea-view-studio/pdf"
    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  # Unpublished property returns 404
  test "GET pdf for unpublished property returns 404" do
    @property.update!(published: false)
    get "/biens/#{@property.id}-studio-carre-dor/pdf"
    assert_response :not_found
  end

  # Show page has PDF download link
  test "property show page contains PDF download link" do
    get "/biens/#{@property.id}-studio-carre-dor"
    assert_response :success
    assert_select "a[data-testid='pdf-download-link']"
  end
end
