require "test_helper"

class PropertyMailerTest < ActionMailer::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-TEST-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      intro: { "fr" => "Un écrin rare au coeur de Monaco", "en" => "A rare gem in the heart of Monaco" },
      description: { "fr" => "Magnifique studio avec vue mer", "en" => "Beautiful sea-view studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      num_rooms: 3,
      num_bedrooms: 2,
      num_bathrooms: 2,
      num_parkings: 1,
      living_area: 157.0
    )

    @property.property_images.create!(
      remote_url: "https://cdn.immotoolbox.com/large/photo1.jpg",
      thumb_url: "https://cdn.immotoolbox.com/thumb/photo1.jpg",
      medium_url: "https://cdn.immotoolbox.com/medium/photo1.jpg",
      large_url: "https://cdn.immotoolbox.com/large/photo1.jpg",
      position: 1
    )

    @contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
  end

  # Seeds the brochure cache with both French logo variants (distinct bytes so
  # a test can tell which variant was attached) without running Typst.
  def attach_fake_brochures
    { true => "%PDF-logo", false => "%PDF-nologo" }.each do |include_logo, bytes|
      @property.brochures.attach(
        io: StringIO.new(bytes),
        filename: @property.brochure_filename,
        content_type: "application/pdf",
        metadata: { locale: "fr", include_logo: include_logo }
      )
    end
  end

  test "share property is delivered" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "share property is sent to contact email" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_equal [ "jean@example.com" ], email.to
  end

  test "share property is sent from agency" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_equal [ "info@agencegaremonaco.com" ], email.from
  end

  test "share property from header carries the agency display name" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_equal "\"Agence Immobilière de la Gare\" <info@agencegaremonaco.com>", email[:from].decoded
  end

  test "share property reply-to is the sending agent" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_equal [ "adrien@agencegaremonaco.com" ], email.reply_to
  end

  test "share property subject includes property reference and title" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_includes email.subject, "MC-TEST-001"
    assert_includes email.subject, "Studio"
  end

  test "share property body contains property title and intro" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    assert_includes body, "Studio Carré d&#39;Or"
    assert_includes body, "Un écrin rare au coeur de Monaco"
  end

  test "share property body shows the intro, not the description" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    refute_includes body, "Magnifique studio"
  end

  test "share property body shows the full intro without truncation" do
    long_intro = "Situé au coeur du quartier historique de Monaco, ce bien d'exception offre des prestations rares et un emplacement privilégié à deux pas du Port Hercule, des commerces et des écoles internationales, dans une résidence sécurisée avec gardien et services haut de gamme."
    @property.update!(intro: { "fr" => long_intro })
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    # The whole intro must render — including its tail — and no ellipsis.
    assert_includes body, "services haut de gamme."
    refute_includes body, "…"
    refute_includes body, "..."
  end

  test "share property body contains formatted price" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_includes email.body.encoded, "1.290.000"
  end

  test "share property body contains the hero photo" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_includes email.body.encoded, "https://cdn.immotoolbox.com/large/photo1.jpg"
  end

  test "share property body contains the property stats" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    assert_includes body, "157" # living area
    # rooms / bedrooms / bathrooms / parking values
    %w[3 2 1].each { |n| assert_includes body, n }
  end

  test "share property dividers use cell-based spacing, not table margins" do
    # Outlook (Word engine) ignores top/bottom margin on tables, so divider
    # spacing must live in padded/height spacer cells instead.
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    refute_match(/margin:\s*24px/, body)
    assert_includes body, "height:24px"
  end

  test "share property shows stats before the intro" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    assert_operator body.index("Surface"), :<, body.index("Un écrin rare au coeur de Monaco"),
                    "stats strip should render before the intro paragraph"
  end

  test "share property stats use text labels, not inline SVG icons" do
    # Inline <svg> is stripped by most email clients (Gmail/Outlook/Apple Mail),
    # so stats must be labelled with text instead.
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    refute_includes body, "<svg"
    assert_includes body, "Pièces"
    assert_includes body, "Chambres"
    assert_includes body, "Salles de bain"
    assert_includes body, "Parking"
    assert_includes body, "Surface"
  end

  test "share property body contains link to property page" do
    email = PropertyMailer.share_property(@property, @contact)
    assert_includes email.body.encoded, "/fr/biens/#{@property.id}"
  end

  test "share property body contains the sending agent block" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    assert_includes body, "Adrien Maré"
    assert_includes body, "adrien@agencegaremonaco.com"
    assert_includes body, "+33 6 62 39 20 65"
  end

  test "share property body contains agency footer info" do
    email = PropertyMailer.share_property(@property, @contact)
    body = email.body.encoded
    assert_includes body, "3, Rue Langlé"
    assert_includes body, "(+377) 93 30 22 36"
    assert_includes body, "agencegaremonaco.com"
  end

  test "share property body contains the agency logo" do
    email = PropertyMailer.share_property(@property, @contact)
    # Host is prepended in production via action_mailer.asset_host; here we just
    # assert the logo asset is referenced.
    assert_match %r{/assets/logo[^"]*\.png}, email.body.encoded
  end

  test "share property with nil contact still renders" do
    email = PropertyMailer.share_property(@property, nil)
    body = email.body.encoded
    assert_includes body, "Studio Carré d&#39;Or"
    assert_includes body, "Adrien Maré"
  end

  # --- admin-customized share (subject / personal note / PDF brochure) ---

  test "share property uses the admin-provided subject" do
    email = PropertyMailer.share_property(@property, @contact, subject: "Une opportunité rare")
    assert_equal "Une opportunité rare", email.subject
  end

  test "the blank-subject fallback is the shared default_share_subject" do
    # Single source of truth: the share form prefill and the mailer fallback
    # both read this, so an untouched field always sends the same email.
    email = PropertyMailer.share_property(@property, @contact, subject: "")
    assert_equal PropertyMailer.default_share_subject(@property), email.subject
  end

  test "share property renders the personal note above the agent signature block" do
    email = PropertyMailer.share_property(@property, @contact, body: "Bonjour Jean,\nvoici un bien pour vous.")
    body = email.body.encoded
    assert_includes body, "Bonjour Jean,<br>voici un bien pour vous."
    assert_operator body.index("Bonjour Jean,"), :<, body.index("adrien@agencegaremonaco.com"),
                    "the agent block reads as the signature, so it must follow the note"
    assert_operator body.index("adrien@agencegaremonaco.com"), :<, body.index("https://cdn.immotoolbox.com/large/photo1.jpg"),
                    "the signature should still render before the hero photo"
  end

  test "share property HTML-escapes the personal note" do
    email = PropertyMailer.share_property(@property, @contact, body: "Prix < 2M & <b>vue mer</b>")
    body = email.body.encoded
    assert_includes body, "Prix &lt; 2M &amp; &lt;b&gt;vue mer&lt;/b&gt;"
    refute_includes body, "<b>vue mer</b>"
  end

  test "share property attaches the cached French brochure when asked" do
    attach_fake_brochures
    email = PropertyMailer.share_property(@property, @contact, attach_pdf: true)

    assert_equal 1, email.attachments.size
    attachment = email.attachments.first
    assert_equal @property.brochure_filename, attachment.filename
    assert_equal "application/pdf", attachment.mime_type
    assert_equal "%PDF-logo", attachment.body.raw_source
  end

  test "share property attaches the no-logo brochure variant when logo is off" do
    attach_fake_brochures
    email = PropertyMailer.share_property(@property, @contact, attach_pdf: true, include_logo: false)
    assert_equal "%PDF-nologo", email.attachments.first.body.raw_source
  end

  test "share property attaches nothing by default" do
    attach_fake_brochures
    email = PropertyMailer.share_property(@property, @contact)
    assert_empty email.attachments
  end

  test "share property with an attachment still renders the property card" do
    attach_fake_brochures
    email = PropertyMailer.share_property(@property, @contact, attach_pdf: true, body: "Bonjour")
    html = email.html_part.body.encoded
    assert_includes html, "Studio Carré d&#39;Or"
    assert_includes html, "Bonjour"
  end
end
