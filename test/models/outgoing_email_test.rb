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

  test "decrement_and_maybe_purge! decrements but keeps the record above zero" do
    email = build_email(pending_count: 2)
    email.save!
    email.decrement_and_maybe_purge!
    assert OutgoingEmail.exists?(email.id)
    assert_equal 1, email.reload.pending_count
  end

  test "decrement_and_maybe_purge! destroys the record and purges the blob at zero" do
    email = build_email(pending_count: 1)
    email.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    email.save!
    blob_id = email.file.blob.id

    email.decrement_and_maybe_purge!

    assert_not OutgoingEmail.exists?(email.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "decrement_and_maybe_purge! purges exactly once under concurrent last calls" do
    email = build_email(pending_count: 1)
    email.save!

    # Two references to the same row both call the last decrement. Exactly one
    # should win the destroy; the other must not raise.
    a = OutgoingEmail.find(email.id)
    b = OutgoingEmail.find(email.id)
    assert_nothing_raised do
      a.decrement_and_maybe_purge!
      b.decrement_and_maybe_purge!
    end
    assert_not OutgoingEmail.exists?(email.id)
  end
end
