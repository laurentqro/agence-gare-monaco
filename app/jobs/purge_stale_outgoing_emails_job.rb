class PurgeStaleOutgoingEmailsJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 24.hours

  # Safety net for orphaned OutgoingEmail rows: a healthy send tears its own
  # record down via mark_sent! the moment the last recipient is claimed, so any
  # row still alive past STALE_AFTER is an orphan (a recipient whose send has
  # failed for a full day, or a record whose teardown itself failed). STALE_AFTER
  # is a floor, not the exact lifetime: the daily schedule means an orphan can
  # live up to STALE_AFTER + ~24h before a sweep reaches it. We never reap a
  # recently-created, still-draining record, so an in-flight send is safe.
  def perform
    stale = OutgoingEmail.where(created_at: ..STALE_AFTER.ago)
    count = stale.count
    stale.find_each do |email|
      email.file.purge if email.file.attached?
      email.destroy
    end
    Rails.logger.info("[PurgeStaleOutgoingEmailsJob] purged #{count} orphaned record(s)") if count.positive?
  end
end
