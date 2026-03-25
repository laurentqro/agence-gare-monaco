require "test_helper"

class PropertyMailerTest < ActionMailer::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-TEST-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio avec vue mer", "en" => "Beautiful sea-view studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      num_rooms: 2,
      num_bedrooms: 1,
      living_area: 45.0
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

  test "share email is delivered" do
    email = PropertyMailer.share_email(@property, @contact)
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "share email is sent to contact email" do
    email = PropertyMailer.share_email(@property, @contact)
    assert_equal [ "jean@example.com" ], email.to
  end

  test "share email is sent from agency" do
    email = PropertyMailer.share_email(@property, @contact)
    assert_equal [ "info@agencegaremonaco.com" ], email.from
  end

  test "share email subject includes property reference and title" do
    email = PropertyMailer.share_email(@property, @contact)
    assert_includes email.subject, "MC-TEST-001"
    assert_includes email.subject, "Studio"
  end

  test "share email body contains property details" do
    email = PropertyMailer.share_email(@property, @contact)
    body = email.body.encoded
    assert_includes body, "MC-TEST-001"
    assert_includes body, "1.290.000"
    assert_includes body, "Magnifique studio"
  end

  test "share email body contains property photos" do
    email = PropertyMailer.share_email(@property, @contact)
    body = email.body.encoded
    assert_includes body, "https://cdn.immotoolbox.com/medium/photo1.jpg"
  end

  test "share email body contains link to property page" do
    email = PropertyMailer.share_email(@property, @contact)
    body = email.body.encoded
    assert_includes body, "/fr/biens/#{@property.id}"
  end

  test "share email body contains contact first name" do
    email = PropertyMailer.share_email(@property, @contact)
    body = email.body.encoded
    assert_includes body, "Jean"
  end

  test "share email body contains agency contact info" do
    email = PropertyMailer.share_email(@property, @contact)
    body = email.body.encoded
    assert_includes body, "info@agencegaremonaco.com"
    assert_includes body, "+377 93 30 22 36"
  end
end
