require "test_helper"

class SendOutgoingEmailJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @outgoing = OutgoingEmail.create!(subject: "Hi", body: "Body", pending_count: 2)
  end

  test "delivers exactly one email to the right recipient" do
    assert_emails 1 do
      SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    end
    assert_equal [ "jean@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "a non-last job decrements but leaves the record intact" do
    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    assert OutgoingEmail.exists?(@outgoing.id)
    assert_equal 1, @outgoing.reload.pending_count
  end

  test "the last job purges the record and its blob" do
    @outgoing.update!(pending_count: 1)
    @outgoing.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    blob_id = @outgoing.file.blob.id

    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")

    assert_not OutgoingEmail.exists?(@outgoing.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "missing record id is a no-op (does not raise)" do
    assert_nothing_raised do
      SendOutgoingEmailJob.perform_now(-1, "jean@example.com", "Jean Dupont")
    end
  end

  test "a replayed job for the same recipient does not re-send or re-decrement" do
    # Simulates Solid Queue re-dispatching a job after a worker crash: the first
    # run sends and counts the recipient down; the replay must be a silent no-op.
    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    assert_equal 1, @outgoing.reload.pending_count

    assert_no_emails do
      SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    end
    assert_equal 1, @outgoing.reload.pending_count, "a replay must not decrement again"
  end

  test "distinct recipients each send and count down" do
    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    SendOutgoingEmailJob.perform_now(@outgoing.id, "marie@example.com", "Marie Aubert")
    # Both recipients claimed -> record torn down.
    assert_not OutgoingEmail.exists?(@outgoing.id)
  end
end
