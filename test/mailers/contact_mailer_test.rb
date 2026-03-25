require "test_helper"

class ContactMailerTest < ActionMailer::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-TEST-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000
    )
  end

  # === Homepage contact form email ===

  test "contact email is sent to agency" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "General enquiry",
      message: "I would like more information about your services."
    )

    email = ContactMailer.contact_email(submission)
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "contact email has correct recipient" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "General enquiry",
      message: "I would like more information."
    )

    email = ContactMailer.contact_email(submission)
    assert_equal [ "info@agencegaremonaco.com" ], email.to
  end

  test "contact email has correct reply-to" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "General enquiry",
      message: "I would like more information."
    )

    email = ContactMailer.contact_email(submission)
    assert_equal [ "jean@example.com" ], email.reply_to
  end

  test "contact email subject includes submission subject" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "General enquiry",
      message: "I would like more information."
    )

    email = ContactMailer.contact_email(submission)
    assert_includes email.subject, "General enquiry"
  end

  test "contact email body contains sender name and message" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "General enquiry",
      message: "I would like more information about your services."
    )

    email = ContactMailer.contact_email(submission)
    assert_includes email.body.encoded, "Jean Dupont"
    assert_includes email.body.encoded, "I would like more information about your services."
    assert_includes email.body.encoded, "jean@example.com"
  end

  # === Property enquiry email ===

  test "enquiry email is sent to agency" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      phone: "+33 6 12 34 56 78",
      country: "France",
      message: "I am interested in this property.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    assert_emails 1 do
      email.deliver_now
    end
  end

  test "enquiry email has correct recipient" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      message: "I am interested.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    assert_equal [ "info@agencegaremonaco.com" ], email.to
  end

  test "enquiry email has correct reply-to" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      message: "I am interested.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    assert_equal [ "pierre@example.com" ], email.reply_to
  end

  test "enquiry email subject includes property reference" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      message: "I am interested.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    assert_includes email.subject, "MC-TEST-001"
  end

  test "enquiry email body contains sender details and property info" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      phone: "+33 6 12 34 56 78",
      country: "France",
      message: "I am interested in this property.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    body = email.body.encoded
    assert_includes body, "Pierre Martin"
    assert_includes body, "pierre@example.com"
    assert_includes body, "+33 6 12 34 56 78"
    assert_includes body, "France"
    assert_includes body, "I am interested in this property."
    assert_includes body, "MC-TEST-001"
  end

  test "enquiry email body contains link to property" do
    submission = ContactSubmission.create!(
      form_type: "enquiry",
      name: "Pierre Martin",
      email: "pierre@example.com",
      message: "I am interested.",
      property: @property
    )

    email = ContactMailer.enquiry_email(submission)
    body = email.body.encoded
    assert_includes body, "/fr/biens/#{@property.id}"
  end
end
