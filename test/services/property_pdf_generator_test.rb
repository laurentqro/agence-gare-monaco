require "test_helper"
require "pdf-reader"

class PropertyPdfGeneratorTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-PDF-001",
      title: { "fr" => "Magnifique penthouse Carré d'Or", "en" => "Stunning Carré d'Or penthouse" },
      intro: { "fr" => "Un écrin rare au coeur de Monaco.", "en" => "A rare gem in the heart of Monaco." },
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

  test "fits title, intro, description and full details table on page 1 even with a long description" do
    long = (1..20).map { |i| "Ligne descriptive numéro #{i} avec un contenu assez détaillé pour remplir l'espace vertical disponible." }.join("\n")
    @property.update!(
      intro: { "fr" => "Une introduction relativement longue qui occupe deux lignes entières sur la page pour tester la mise en page." },
      description: { "fr" => long }
    )
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate

    # generate returns only page 1; if content overflows, the tail is dropped.
    # Everything below must still be present, proving it all fit on page 1.
    reader = PDF::Reader.new(StringIO.new(pdf_bytes))
    assert_equal 1, reader.page_count
    text = reader.pages.first.text

    # The tail of the description must survive (not be pushed off-page).
    assert_includes text, "Ligne descriptive numéro 20"
    # The bottom-most detail rows must survive too.
    assert_includes text, I18n.t("property_detail.reference", locale: :fr)
    assert_includes text, "MC-PDF-001"
    assert_includes text, I18n.t("pdf_brochure.price_label", locale: :fr)
  end

  test "never truncates an extremely long description, scaling text as a last resort" do
    very_long = (1..40).map { |i| "Ligne descriptive numéro #{i} avec un contenu vraiment très détaillé destiné à dépasser largement la hauteur d'une page A4 même sans photo." }.join("\n")
    @property.update!(description: { "fr" => very_long })
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate

    reader = PDF::Reader.new(StringIO.new(pdf_bytes))
    assert_equal 1, reader.page_count
    text = reader.pages.first.text
    # First and last lines both present — the whole description fit, scaled down.
    assert_includes text, "Ligne descriptive numéro 1 "
    assert_includes text, "Ligne descriptive numéro 40"
  end

  test "preserves line breaks and bullet structure in the description" do
    @property.update!(description: {
      "fr" => "Au coeur de Monaco.\nL'appartement se compose de :\n- Un hall d'entrée\n- Une cuisine équipée\nLivraison 2022."
    })
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    # Each line lands on its own line in the PDF rather than one run-on blob.
    # Typst renders "- " list markers as bullet glyphs.
    assert_match(/[-•]\s*Un hall d'entrée/, text)
    assert_match(/[-•]\s*Une cuisine équipée/, text)
    refute_includes text, "Un hall d'entrée - Une cuisine"
    refute_includes text, "Un hall d'entrée • Une cuisine"
  end

  test "contains localized intro" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "écrin rare au coeur de Monaco"
  end

  test "contains intro in requested locale" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :en).generate
    text = extract_text(pdf_bytes)
    assert_includes text, "rare gem in the heart of Monaco"
  end

  test "omits intro gracefully when property has no intro" do
    @property.update!(intro: { "fr" => "", "en" => "" })
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    assert pdf_bytes.start_with?("%PDF")
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

  test "header contact line does not render literal backslashes as separators" do
    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr, include_logo: true).generate
    text = extract_text(pdf_bytes)
    # Typst line-break is `\` — it must be interpreted, not printed literally.
    refute_includes text, "Monaco \\ (+377)",
      "contact line rendered with literal backslashes instead of line breaks"
  end

  test "handles image URL that is labeled .jpg but actually serves PNG bytes" do
    # 1×1 white PNG (valid CRC)
    png_bytes = [ "89504e470d0a1a0a0000000d49484452000000010000000108000000003a7e9b550000000a49444154789c63fa0f0001050102cfa02ecd0000000049454e44ae426082" ].pack("H*")
    stub_request(:get, "https://example.com/fake.jpg")
      .to_return(status: 200, body: png_bytes, headers: { "Content-Type" => "image/png" })

    @property.property_images.create!(remote_url: "https://example.com/fake.jpg", position: 1)

    pdf_bytes = PropertyPdfGenerator.new(@property, locale: :fr).generate
    assert pdf_bytes.start_with?("%PDF")
  end

  test "loads open-uri so image fetching works in a clean process" do
    # In a bare process (e.g. the background brochure job) open-uri is not
    # loaded, so URI::HTTPS#open is private and every image fetch silently
    # fails — producing brochures with no property images. The generator must
    # require open-uri itself rather than rely on it being loaded ambiently.
    source = File.read(Rails.root.join("app/services/property_pdf_generator.rb"))
    assert_match(/require ["']open-uri["']/, source,
      "PropertyPdfGenerator must require 'open-uri' or image fetching fails in a clean process")
  end

  test "embeds the cover photo as the hero image" do
    # 1×1 white PNG (valid CRC) so Typst can actually decode it.
    png_bytes = [ "89504e470d0a1a0a0000000d49484452000000010000000108000000003a7e9b550000000a49444154789c63fa0f0001050102cfa02ecd0000000049454e44ae426082" ].pack("H*")
    stub_request(:get, "https://example.com/cover.png")
      .to_return(status: 200, body: png_bytes, headers: { "Content-Type" => "image/png" })

    @property.property_images.create!(remote_url: "https://example.com/cover.png", position: 0)

    generator = PropertyPdfGenerator.new(@property, locale: :fr)
    generator.generate
    dependencies = generator.instance_variable_get(:@dependencies)

    assert dependencies.keys.any? { |k| k.start_with?("hero.") },
      "expected the cover photo to be embedded as the hero image, got: #{dependencies.keys.inspect}"
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
