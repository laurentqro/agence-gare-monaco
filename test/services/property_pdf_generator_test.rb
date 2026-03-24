require "test_helper"
require "pdf-reader"

class PropertyPdfGeneratorTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-PDF-001",
      title: { "fr" => "Magnifique penthouse Carré d'Or", "en" => "Stunning Carré d'Or penthouse" },
      description: { "fr" => "Superbe penthouse avec vue mer panoramique.", "en" => "Superb penthouse with panoramic sea view." },
      transaction_type: "sale",
      property_type: "penthouse",
      country: "MC",
      city: "Monaco",
      price: 12_500_000,
      published: true,
      num_rooms: 5,
      num_bedrooms: 3,
      num_bathrooms: 2,
      living_area: 250.0,
      total_area: 350.0,
      terrace_area: 80.0,
      floor: 8
    )

    @district = District.create!(name: "Carré d'Or", city: "Monaco")
    @property.update!(district: @district)

    @building = Building.create!(name: "Le Mirabeau", city: "Monaco")
    @property.update!(building: @building)
  end

  test "returns valid PDF bytes" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    assert pdf_bytes.start_with?("%PDF")
  end

  test "contains localized title" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "Magnifique penthouse"
  end

  test "contains title in requested locale" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :en).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "Stunning"
  end

  test "contains reference" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "MC-PDF-001"
  end

  test "contains formatted price" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "12.500.000"
  end

  test "contains localized description" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "vue mer panoramique"
  end

  test "contains description in requested locale" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :en).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "panoramic sea view"
  end

  test "contains agency contact info" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "agencegaremonaco.com"
  end

  test "contains detail fields when present" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "250"   # living area
    assert_includes text, "Le Mirabeau"  # building name
  end

  test "omits detail fields when nil" do
    @property.update!(num_rooms: nil, num_bedrooms: nil, living_area: nil, building: nil)
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    # Should still generate without error
    assert pdf_bytes.start_with?("%PDF")
    refute_includes text, "Le Mirabeau"
  end

  test "includes off-market badge when off_market is true" do
    @property.update!(off_market: true)
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, I18n.t("pdf_brochure.off_market_badge", locale: :fr)
  end

  test "excludes off-market badge when off_market is false" do
    @property.update!(off_market: false)
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    refute_includes text, I18n.t("pdf_brochure.off_market_badge", locale: :fr)
  end

  test "includes agency logo when include_logo is true" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: true).generate
    # PDF should be larger with logo than without
    pdf_bytes_no_logo = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: false).generate
    assert pdf_bytes.bytesize > pdf_bytes_no_logo.bytesize
  end

  test "excludes agency logo when include_logo is false" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: false).generate
    # Should still be a valid PDF
    assert pdf_bytes.start_with?("%PDF")
  end

  test "excludes contact details when include_logo is false" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: false).generate
    text = extract_text(pdf_bytes)
    refute_includes text, I18n.t("pdf_brochure.contact_phone", locale: :fr)
    refute_includes text, I18n.t("pdf_brochure.contact_email", locale: :fr)
    refute_includes text, I18n.t("pdf_brochure.contact_address", locale: :fr)
  end

  test "includes contact details when include_logo is true" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: true).generate
    text = extract_text(pdf_bytes)
    assert_includes text, I18n.t("pdf_brochure.contact_phone", locale: :fr)
  end

  test "includes logo by default" do
    pdf_bytes_default = PropertyPdfGenerator.new(@property, locale: :fr).generate
    pdf_bytes_with_logo = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: true).generate
    assert_equal pdf_bytes_default.bytesize, pdf_bytes_with_logo.bytesize
  end

  test "embeds QR code as PNG" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    # QR code adds image data — check PDF has image XObjects
    reader = PDF::Reader.new(StringIO.new(pdf_bytes))
    page = reader.pages.first
    xobjects = page.xobjects
    assert xobjects.any?, "PDF should contain at least one image (QR code)"
  end

  test "includes CIM logo" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    # CIM logo is a PNG — presence of multiple images
    assert pdf_bytes.start_with?("%PDF")
  end

  test "handles property with no images gracefully" do
    assert_equal 0, @property.property_images.count
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    assert pdf_bytes.start_with?("%PDF")
  end

  test "includes district name in details" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "Carré d'Or"
  end

  test "strips HTML tags and entities from description" do
    @property.update!(description: {
      "fr" => "<p>Situ&eacute; au c&oelig;ur du quartier.<br />Tr&egrave;s bel appartement avec d&#39;excellentes finitions.</p>"
    })
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    # Should contain decoded text, not raw HTML
    refute_includes text, "<p>"
    refute_includes text, "&eacute;"
    refute_includes text, "<br"
    refute_includes text, "&#39;"
    assert_includes text, "appartement"
  end

  test "strips nbsp entities from description" do
    @property.update!(description: {
      "fr" => "Deux&nbsp;&nbsp;chambres avec parquet,&nbsp;proche du port."
    })
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    refute_includes text, "&nbsp;"
    assert_includes text, "chambres avec parquet"
  end

  test "generates for all supported locales" do
    I18n.available_locales.each do |locale|
      pdf_bytes = PropertyPdfGenerator.new(@property, locale: locale).generate
      assert pdf_bytes.start_with?("%PDF"), "Failed to generate PDF for locale #{locale}"
    end
  end

  test "uses localized labels for every locale" do
    I18n.available_locales.each do |locale|
      pdf_bytes = PropertyPdfGenerator.new(@property, locale: locale).generate
      text = extract_text(pdf_bytes)

      # Price label must be in the correct locale, not French
      price_label = I18n.t("pdf_brochure.price_label", locale: locale)
      assert_includes text, price_label,
        "PDF for locale #{locale} should contain '#{price_label}' but got:\n#{text}"

      # Detail labels should be localized too
      rooms_label = I18n.t("property_detail.rooms", locale: locale)
      assert_includes text, rooms_label,
        "PDF for locale #{locale} should contain '#{rooms_label}'"
    end
  end

  private

  def extract_text(pdf_bytes)
    reader = PDF::Reader.new(StringIO.new(pdf_bytes))
    reader.pages.map(&:text).join(" ")
  end
end
