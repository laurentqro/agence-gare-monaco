require "test_helper"

class OutgoingEmailTest < ActiveSupport::TestCase
  def build_email(**attrs)
    OutgoingEmail.new({ subject: "Bonjour", body: "Un message.", pending_count: 1 }.merge(attrs))
  end

  test "valid with subject, body and pending_count" do
    assert build_email.valid?
  end

  test "requires a subject" do
    email = build_email(subject: "")
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :subject
  end

  test "requires a body" do
    email = build_email(body: "")
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :body
  end

  test "accepts an attachment up to 10 MB" do
    email = build_email
    email.file.attach(
      io: StringIO.new("a" * 1.megabyte),
      filename: "ok.pdf",
      content_type: "application/pdf"
    )
    assert email.valid?
  end

  test "rejects an attachment over 10 MB" do
    email = build_email
    email.file.attach(
      io: StringIO.new("a" * (10.megabytes + 1)),
      filename: "too-big.pdf",
      content_type: "application/pdf"
    )
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :file
  end

  test "mark_sent! decrements but keeps the record while recipients remain" do
    email = build_email(pending_count: 2)
    email.save!
    email.mark_sent!("a@example.com")
    assert OutgoingEmail.exists?(email.id)
    assert_equal 1, email.reload.pending_count
  end

  test "mark_sent! destroys the record and purges the blob once the last recipient is claimed" do
    email = build_email(pending_count: 1)
    email.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    email.save!
    blob_id = email.file.blob.id

    email.mark_sent!("a@example.com")

    assert_not OutgoingEmail.exists?(email.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "mark_sent! purges exactly once even if two jobs claim the last two recipients at once" do
    email = build_email(pending_count: 2)
    email.save!

    # Two stale references each claim a DISTINCT final recipient; exactly one
    # drives the count to 0 and tears down, and neither raises.
    a = OutgoingEmail.find(email.id)
    b = OutgoingEmail.find(email.id)
    assert_nothing_raised do
      a.mark_sent!("a@example.com")
      b.mark_sent!("b@example.com")
    end
    assert_not OutgoingEmail.exists?(email.id)
  end

  test "mark_sent! records a recipient and reports first delivery as true" do
    email = build_email(pending_count: 2)
    email.save!
    assert email.mark_sent!("a@example.com"), "first delivery to a recipient is new"
    assert_equal [ "a@example.com" ], email.reload.sent_emails
  end

  test "mark_sent! is idempotent: a repeat for the same recipient reports false and does not re-record" do
    email = build_email(pending_count: 2)
    email.save!
    email.mark_sent!("a@example.com")
    refute email.mark_sent!("a@example.com"), "a replayed delivery to the same recipient is not new"
    assert_equal [ "a@example.com" ], email.reload.sent_emails
  end

  test "mark_sent! is atomic across two stale references to the same row" do
    email = build_email(pending_count: 2)
    email.save!
    a = OutgoingEmail.find(email.id)
    b = OutgoingEmail.find(email.id)
    # Both stale copies try to claim the SAME recipient: exactly one wins.
    results = [ a.mark_sent!("a@example.com"), b.mark_sent!("a@example.com") ]
    assert_equal [ true, false ], results.sort_by { |x| x ? 0 : 1 }
    assert_equal [ "a@example.com" ], email.reload.sent_emails
  end
end
