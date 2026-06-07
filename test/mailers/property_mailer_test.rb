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
end
