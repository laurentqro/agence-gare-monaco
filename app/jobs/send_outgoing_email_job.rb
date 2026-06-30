class SendOutgoingEmailJob < ApplicationJob
  queue_as :default

  def perform(outgoing_email_id, recipient_email, recipient_name)
    outgoing_email = OutgoingEmail.find_by(id: outgoing_email_id)
    return if outgoing_email.nil?

    OutgoingEmailMailer.compose(outgoing_email, recipient_email, recipient_name).deliver_now
    outgoing_email.decrement_and_maybe_purge!
  end
end
