class SharePropertyEmailJob < ApplicationJob
  queue_as :default

  # One job per recipient so a single failure never blocks other recipients.
  # The PropertyShare record carries the send options and tracks claimed
  # recipients, so a replay (worker crash recovery, operator retry) never
  # re-sends: sent contacts are skipped, and mark_sent! purges the record when
  # the last recipient completes.
  def perform(property_share_id, contact_id)
    share = PropertyShare.find_by(id: property_share_id)
    # Nil means the batch already completed (or its property was deleted, which
    # destroys its shares), so a replay is a silent no-op.
    return if share.nil?
    return if share.sent_contact_ids.include?(contact_id)

    contact = Contact.find_by(id: contact_id)
    if contact.nil?
      # Deleted between enqueue and run: claim it anyway so the batch still
      # counts down and the record purges.
      share.mark_sent!(contact_id)
      return
    end

    PropertyMailer.share_property(
      share.property, contact,
      subject: share.subject, body: share.body,
      attach_pdf: share.attach_pdf, include_logo: share.include_logo
    ).deliver_now
    share.mark_sent!(contact_id)
  end
end
