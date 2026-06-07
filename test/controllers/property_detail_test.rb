require "test_helper"

class PropertyDetailTest < ActionDispatch::IntegrationTest
  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @building = Building.create!(name: "Le Montaigne", address: "1 Av. Princess Grace", city: "Monaco", district: @district)

    @property = Property.create!(
      reference: "MC-100",
      title: { "fr" => "Studio vue mer Carré d'Or", "en" => "Sea view studio Carré d'Or" },
      intro: { "fr" => "Un écrin rare au coeur de Monaco.", "en" => "A rare gem in the heart of Monaco." },
      description: { "fr" => "Magnifique studio avec vue mer dans le prestigieux Carré d'Or.", "en" => "Beautiful sea view studio in the prestigious Carré d'Or." },
      transaction_type: "sale",
      property_type: "apartment",
      subtype: "studio",
      country: "MC",
      city: "Monaco",
      district: @district,
      building: @building,
      price: 1_850_000,
      currency: "EUR",
      num_rooms: 1,
      num_bedrooms: 0,
      num_bathrooms: 1,
      num_parkings: 1,
      num_cellars: 1,
      living_area: 35.5,
      terrace_area: 8.0,
      floor: 7,
      furnished: true,
      published: true,
      exclusivity: true,
      video_url: "https://www.youtube.com/watch?v=abc123",
      virtual_tour_url: "https://agencegaremonaco.com/tours/82844/360.html"
    )

    # Create property images (photos)
    @image1 = @property.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/images/photo1.jpg",
      thumb_url: "https://cdn.immotoolbox.com/images/photo1_thumb.jpg",
      small_url: "https://cdn.immotoolbox.com/images/photo1_small.jpg",
      medium_url: "https://cdn.immotoolbox.com/images/photo1_medium.jpg",
      large_url: "https://cdn.immotoolbox.com/images/photo1_large.jpg",
      position: 0,
      is_plan: false
    )
    @image2 = @property.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/images/photo2.jpg",
      thumb_url: "https://cdn.immotoolbox.com/images/photo2_thumb.jpg",
      small_url: "https://cdn.immotoolbox.com/images/photo2_small.jpg",
      medium_url: "https://cdn.immotoolbox.com/images/photo2_medium.jpg",
      large_url: "https://cdn.immotoolbox.com/images/photo2_large.jpg",
      position: 1,
      is_plan: false
    )
    # Floor plan image
    @plan = @property.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/images/plan1.jpg",
      thumb_url: "https://cdn.immotoolbox.com/images/plan1_thumb.jpg",
      small_url: "https://cdn.immotoolbox.com/images/plan1_small.jpg",
      medium_url: "https://cdn.immotoolbox.com/images/plan1_medium.jpg",
      large_url: "https://cdn.immotoolbox.com/images/plan1_large.jpg",
      position: 10,
      is_plan: true
    )

    # Similar property in the same district
    @similar = Property.create!(
      reference: "MC-101",
      title: { "en" => "Another studio Carré d'Or", "fr" => "Autre studio Carré d'Or" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      price: 2_100_000,
      published: true
    )
    @similar.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/images/similar1.jpg",
      position: 0
    )
  end

  # === Basic rendering ===

  test "property detail page renders successfully" do
    get "/en/properties/#{@property.id}-sea-view-studio-carre-d-or"
    assert_response :success
  end

  test "property detail page works with just the ID (ignores slug)" do
    get "/en/properties/#{@property.id}-wrong-slug"
    assert_response :success
  end

  test "property detail page renders in French locale" do
    get "/biens/#{@property.id}-studio-vue-mer-carre-d-or"
    assert_response :success
  end

  test "property detail page renders for all 9 locales" do
    locales_with_properties = {
      en: "properties", it: "immobili", de: "immobilien",
      sv: "fastigheter", no: "eiendommer", da: "ejendomme", fi: "kiinteistot", ru: "obekty"
    }
    # French has no locale prefix
    get "/biens/#{@property.id}-slug"
    assert_response :success, "Failed for locale fr"

    locales_with_properties.each do |locale, segment|
      get "/#{locale}/#{segment}/#{@property.id}-slug"
      assert_response :success, "Failed for locale #{locale}"
    end
  end

  # === Property title and description ===

  test "displays property title in current locale" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-title']", text: /Sea view studio/
  end

  test "displays property title in French locale" do
    get "/biens/#{@property.id}-slug"
    assert_select "[data-testid='property-title']", text: /Studio vue mer/
  end

  test "displays property description in current locale" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-description']", text: /Beautiful sea view studio/
  end

  test "renders multi-line description with paragraph and line breaks" do
    @property.update!(description: { "en" => "First paragraph.\n\nIntro line:\n- Bullet one\n- Bullet two" })
    get "/en/properties/#{@property.id}-slug"
    # Blank line becomes a separate paragraph.
    assert_select "[data-testid='property-description'] p", minimum: 2
    # Single newlines within a paragraph become <br> line breaks.
    assert_select "[data-testid='property-description'] br", minimum: 2
    assert_select "[data-testid='property-description']", text: /Bullet one/
  end

  test "displays property intro in current locale" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-intro']", text: /A rare gem in the heart of Monaco/
  end

  test "displays property intro in French locale" do
    get "/biens/#{@property.id}-slug"
    assert_select "[data-testid='property-intro']", text: /Un écrin rare au coeur de Monaco/
  end

  test "omits intro element when property has no intro" do
    @property.update!(intro: { "fr" => "", "en" => "" })
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-intro']", false
  end

  # === Price display ===

  test "displays price with European formatting" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-price']", text: /1\.850\.000/
  end

  test "displays price on request when price is nil" do
    @property.update!(price: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-price']", text: /Price on request/
  end

  # === Property details table ===

  test "displays property reference" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']", text: /MC-100/
  end

  test "displays building name" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']", text: /Le Montaigne/
  end

  test "displays district name" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']", text: /Carré d'Or/
  end

  test "displays property type" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']"
  end

  test "displays room count" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/Rooms/, details)
  end

  test "displays bathroom count" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/Bathrooms/, details)
  end

  test "displays living area" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/35 m²/, details)
  end

  test "displays terrace area" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/8 m²/, details)
  end

  test "displays floor" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/Floor/, details)
    assert_match(/>7</, details)
  end

  test "displays parking count" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/Parking/, details)
  end

  test "displays cellar count" do
    get "/en/properties/#{@property.id}-slug"
    details = css_select("[data-testid='property-details']").to_html
    assert_match(/Cellars/, details)
  end

  test "displays furnished status when true" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']", text: /Furnished/i
  end

  test "does not display furnished when false" do
    @property.update!(furnished: false)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']"
    assert_no_match(/Furnished/i, response.body.gsub(/Unfurnished/i, ""))
  end

  test "displays service charges when present" do
    @property.update!(service_charges: 500)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-details']", text: /500/
  end

  # === Photo gallery ===

  test "displays property photo gallery" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-gallery']"
  end

  test "displays all property photos (excluding plans)" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-gallery'] img[data-gallery-photo]", 2
  end

  test "photo gallery uses large image URLs" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-gallery'] img[src*='photo1_large']"
  end

  test "first photo is eager-loaded" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-gallery'] img[loading='eager']", { minimum: 1 }
  end

  test "subsequent photos are lazy-loaded" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-gallery'] img[loading='lazy']", { minimum: 1 }
  end

  test "gallery images have proper alt text" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "img[alt='Sea view studio Carré d\\'Or - Photo 1']"
  end

  test "displays thumbnail navigation" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='gallery-thumbnails']"
    assert_select "[data-testid='gallery-thumbnails'] img", { minimum: 2 }
  end

  # === Floor plans ===

  test "displays floor plans section when plans exist" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='floor-plans']"
  end

  test "displays floor plan images" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='floor-plans'] img[src*='plan1_large']"
  end

  test "floor plan has proper alt text" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "img[alt*='Plan']"
  end

  test "floor plans section hidden when no plans exist" do
    @plan.destroy!
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='floor-plans']", count: 0
  end

  # === Virtual tour and video ===

  test "embeds krpano tour as iframe when URL ends with .html" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='virtual-tour'] iframe[src='https://agencegaremonaco.com/tours/82844/360.html']"
  end

  test "displays virtual tour link for non-embeddable URLs" do
    @property.update!(virtual_tour_url: "https://example.com/tour/123")
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='virtual-tour'] a[href='https://example.com/tour/123']"
    assert_select "[data-testid='virtual-tour'] iframe", count: 0
  end

  test "hides virtual tour section when no URL" do
    @property.update!(virtual_tour_url: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='virtual-tour']", count: 0
  end

  # === WhatsApp button ===

  test "displays WhatsApp button on property detail page" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='whatsapp-button']"
    assert_select "a[href*='wa.me']"
  end

  test "WhatsApp link in English uses adjective-style description with URL inline" do
    get "/en/properties/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    assert whatsapp_link, "WhatsApp link not found"
    message = CGI.unescape(whatsapp_link["href"])
    # English format: description (url).\n\nCould you please...
    assert_match(/35.5m²/, message)
    assert_match(/1-bedroom/, message)
    assert_match(/flat/, message)
    assert_match(/for sale/, message)
    assert_match(/Le Montaigne/, message)
    assert_match(/agencegaremonaco\.com.*\)\./, message) # URL in parentheses before period
    assert_match(/\.\n\nCould you please/, message) # line break before second sentence
  end

  test "WhatsApp English message with multiple bedrooms" do
    @property.update!(num_rooms: 3, living_area: 75)
    get "/en/properties/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    message = CGI.unescape(whatsapp_link["href"])
    assert_match(/75m²/, message)
    assert_match(/3-bedroom/, message)
  end

  test "WhatsApp message for rental property" do
    @property.update!(transaction_type: "rental")
    get "/en/properties/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    message = CGI.unescape(whatsapp_link["href"])
    assert_match(/for rent/, message)
  end

  test "WhatsApp message without building omits building name" do
    @property.update!(building: nil)
    get "/en/properties/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    message = CGI.unescape(whatsapp_link["href"])
    refute_match(/in Le Montaigne/, message)
  end

  test "WhatsApp message in French uses noun-style description" do
    get "/biens/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    message = CGI.unescape(whatsapp_link["href"])
    # French format: "1 pièce de 35.5m² à la vente dans l'immeuble Le Montaigne"
    assert_match(/1 pièce/, message)
    assert_match(/35.5m²/, message)
    assert_match(/la vente/, message)
    assert_match(/Le Montaigne/, message)
  end

  test "WhatsApp message in non-FR/EN/RU locale uses English text" do
    get "/it/immobili/#{@property.id}-slug"
    whatsapp_link = css_select("[data-testid='whatsapp-button'] a[href*='wa.me']").first
    message = CGI.unescape(whatsapp_link["href"])
    assert_match(/Hello/, message)
    assert_match(/1-bedroom/, message)
    assert_match(/for sale/, message)
  end

  test "displays video section when video URL present" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-video']"
  end

  test "hides video section when no video URL" do
    @property.update!(video_url: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-video']", count: 0
  end

  # === Badges ===

  test "displays exclusivity badge" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='exclusivity-badge']"
  end

  test "hides exclusivity badge when not exclusive" do
    @property.update!(exclusivity: false)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='exclusivity-badge']", count: 0
  end

  test "does not display new badge" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='new-badge']", count: 0
  end

  # === Back to listings link ===

  test "displays back to listings link for sales" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='back-link']"
    assert_select "a[href*='/en/sales']"
  end

  # === Similar properties ===

  test "displays similar properties section" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='similar-properties']"
  end

  test "similar properties shows other properties in same district and transaction type" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='similar-properties'] [data-testid='property-card']", { minimum: 1 }
  end

  test "similar properties does not include the current property" do
    get "/en/properties/#{@property.id}-slug"
    # The similar section should not contain the current property's reference
    similar_html = css_select("[data-testid='similar-properties']").to_html
    assert_no_match(/MC-100/, similar_html)
  end

  # === SEO ===

  test "page title includes property title and price" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "title", text: /Sea view studio.*1\.850\.000/
  end

  test "page title omits price when price on request" do
    @property.update!(price: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_select "title", text: /Sea view studio/
    title_html = css_select("title").text
    assert_no_match(/1\.850\.000/, title_html)
  end

  test "image alt text includes property title and photo number" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "img[alt='Sea view studio Carré d\\'Or - Photo 1']"
    assert_select "img[alt='Sea view studio Carré d\\'Or - Photo 2']"
  end

  test "property images use srcset with CDN size variants" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "img[srcset*='photo1_small']"
    assert_select "img[srcset*='photo1_medium']"
    assert_select "img[srcset*='photo1_large']"
  end

  # === PDF document downloads ===

  test "displays documents section when property has documents" do
    doc = @property.property_documents.create!(label: "Floor Plan PDF")
    doc.file.attach(io: StringIO.new("fake pdf"), filename: "floor_plan.pdf", content_type: "application/pdf")
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-documents']"
  end

  test "displays document download link with label" do
    doc = @property.property_documents.create!(label: "Floor Plan PDF")
    doc.file.attach(io: StringIO.new("fake pdf"), filename: "floor_plan.pdf", content_type: "application/pdf")
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-documents'] a", text: /Floor Plan PDF/
  end

  test "hides documents section when no documents" do
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-documents']", count: 0
  end

  test "displays multiple documents" do
    doc1 = @property.property_documents.create!(label: "Floor Plan")
    doc1.file.attach(io: StringIO.new("fake"), filename: "plan.pdf", content_type: "application/pdf")
    doc2 = @property.property_documents.create!(label: "Brochure")
    doc2.file.attach(io: StringIO.new("fake"), filename: "brochure.pdf", content_type: "application/pdf")
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='property-documents'] a", 2
  end

  # === Off-market properties ===

  test "off-market property is accessible via direct URL" do
    @property.update!(off_market: true)
    get "/en/properties/#{@property.id}-slug"
    assert_response :success
  end

  test "off-market property shows off-market badge" do
    @property.update!(off_market: true)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='off-market-badge']"
  end

  test "off-market property does not show back-to-listings link" do
    @property.update!(off_market: true)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='back-link']", count: 0
  end

  test "off-market property does not show similar properties section" do
    @property.update!(off_market: true)
    get "/en/properties/#{@property.id}-slug"
    assert_select "[data-testid='similar-properties']", count: 0
  end

  test "unpublished property returns 404 even via direct URL" do
    @property.update!(published: false)
    get "/en/properties/#{@property.id}-slug"
    assert_response :not_found
  end

  test "unpublished off-market property returns 404" do
    @property.update!(published: false, off_market: true)
    get "/en/properties/#{@property.id}-slug"
    assert_response :not_found
  end

  # === Edge cases ===

  test "returns 404 for non-existent property" do
    get "/en/properties/999999-non-existent"
    assert_response :not_found
  end

  test "property without images still renders" do
    @property.property_images.destroy_all
    get "/en/properties/#{@property.id}-slug"
    assert_response :success
  end

  test "property without building still renders" do
    @property.update!(building: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_response :success
    # Building row should not appear
    assert_no_match(/Le Montaigne/, response.body)
  end

  test "property without district still renders" do
    @property.update!(district: nil)
    get "/en/properties/#{@property.id}-slug"
    assert_response :success
  end

  test "shows agency logo placeholder when property has no photos" do
    @property.property_images.destroy_all
    get "/biens/#{@property.id}-slug"
    assert_response :success
    assert_select "[data-testid='no-image-placeholder'] img[src*='logo-monogram']"
  end
end
