require "test_helper"

class PurgeStaleOutgoingEmailsJobTest < ActiveJob::TestCase
  test "purges records older than 24 hours and their blobs" do
    stale = OutgoingEmail.create!(subject: "Old", body: "Body", pending_count: 3)
    stale.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    blob_id = stale.file.blob.id
    stale.update_column(:created_at, 25.hours.ago)

    PurgeStaleOutgoingEmailsJob.perform_now

    assert_not OutgoingEmail.exists?(stale.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "leaves recent records untouched even when still draining" do
    # A young record with recipients still pending is a healthy in-flight send,
    # not an orphan; the sweeper must not touch it.
    recent = OutgoingEmail.create!(subject: "New", body: "Body", pending_count: 1)
    recent.update_column(:created_at, 1.hour.ago)

    PurgeStaleOutgoingEmailsJob.perform_now

    assert OutgoingEmail.exists?(recent.id)
  end

  test "reaps an old orphan whose recipients never completed" do
    orphan = OutgoingEmail.create!(subject: "Stuck", body: "Body", pending_count: 2)
    orphan.update_column(:created_at, 30.hours.ago)

    PurgeStaleOutgoingEmailsJob.perform_now

    assert_not OutgoingEmail.exists?(orphan.id)
  end
end
