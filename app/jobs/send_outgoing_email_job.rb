class SendOutgoingEmailJob < ApplicationJob
  queue_as :default

  def perform(outgoing_email_id, recipient_email, recipient_name)
    outgoing_email = OutgoingEmail.find_by(id: outgoing_email_id)
    # Nil means every recipient already completed and the record was torn down,
    # so a replay of an already-finished recipient is a silent no-op.
    return if outgoing_email.nil?
    return if outgoing_email.sent_emails.include?(recipient_email)

    OutgoingEmailMailer.compose(outgoing_email, recipient_email, recipient_name).deliver_now
    # Records the delivery, counts it down, and purges on the last recipient.
    # mark_sent! is idempotent, so a replay that crashed between deliver and mark
    # re-attempts the send but never double-decrements.
    outgoing_email.mark_sent!(recipient_email)
  end
end
