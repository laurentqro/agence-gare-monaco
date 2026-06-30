class PurgeStaleOutgoingEmailsJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 24.hours

  # Safety net for OutgoingEmail rows whose send jobs exhausted retries before
  # decrementing pending_count to 0, leaving an orphaned record + blob.
  def perform
    OutgoingEmail.where("created_at < ?", STALE_AFTER.ago).find_each do |email|
      email.file.purge if email.file.attached?
      email.destroy
    end
  end
end
