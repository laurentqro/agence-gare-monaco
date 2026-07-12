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
    @share = PropertyShare.create!(
      property: @property, subject: "Sujet perso", body: "Bonjour", pending_count: 2
    )
  end

  test "delivers the share email to the contact with the share's options" do
    assert_emails 1 do
      SharePropertyEmailJob.perform_now(@share.id, @contact.id)
    end
    email = ActionMailer::Base.deliveries.last
    assert_equal [ "jean@example.com" ], email.to
    assert_equal "Sujet perso", email.subject
  end

  test "a replayed job never re-sends to an already-claimed contact" do
    SharePropertyEmailJob.perform_now(@share.id, @contact.id)
    assert_no_emails do
      SharePropertyEmailJob.perform_now(@share.id, @contact.id)
    end
    assert_equal 1, @share.reload.pending_count
  end

  test "a non-last delivery decrements but keeps the share record" do
    SharePropertyEmailJob.perform_now(@share.id, @contact.id)
    assert PropertyShare.exists?(@share.id)
    assert_equal 1, @share.reload.pending_count
  end

  test "the last delivery purges the share record" do
    @share.update!(pending_count: 1)
    SharePropertyEmailJob.perform_now(@share.id, @contact.id)
    assert_not PropertyShare.exists?(@share.id)
  end

  test "a deleted contact still counts down so the batch completes" do
    contact_id = @contact.id
    @contact.destroy!
    @share.update!(pending_count: 1)
    assert_no_emails do
      SharePropertyEmailJob.perform_now(@share.id, contact_id)
    end
    assert_not PropertyShare.exists?(@share.id)
  end

  test "is a silent no-op when the share record is gone" do
    share_id = @share.id
    @share.destroy!
    assert_no_emails do
      SharePropertyEmailJob.perform_now(share_id, @contact.id)
    end
  end

  test "is a silent no-op when the property was deleted after enqueue" do
    # dependent: :destroy removes the share with its property, so the job
    # finds nothing to send.
    share_id = @share.id
    @property.destroy!
    assert_no_emails do
      SharePropertyEmailJob.perform_now(share_id, @contact.id)
    end
  end
end
