require "test_helper"

class SharePropertyEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @property = Property.create!(
      reference: "MC-JOB-001",
      title: { "fr" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    @contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
  end

  test "delivers the share email to the contact with the custom subject" do
    assert_emails 1 do
      SharePropertyEmailJob.perform_now(@property.id, @contact.id, "Sujet perso", "Bonjour", false, true)
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "jean@example.com" ], email.to
    assert_equal "Sujet perso", email.subject
  end

  test "is a silent no-op when the contact was deleted after enqueue" do
    contact_id = @contact.id
    @contact.destroy!
    assert_no_emails do
      SharePropertyEmailJob.perform_now(@property.id, contact_id, "S", "B", false, true)
    end
  end

  test "is a silent no-op when the property was deleted after enqueue" do
    property_id = @property.id
    @property.destroy!
    assert_no_emails do
      SharePropertyEmailJob.perform_now(property_id, @contact.id, "S", "B", false, true)
    end
  end
end
