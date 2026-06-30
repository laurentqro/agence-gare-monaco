class OutgoingEmailMailer < ApplicationMailer
  # Replies reach Adrien while the verified agency address stays the From (keeps
  # Brevo/DKIM alignment). Single source of truth shared with PropertyMailer.
  REPLY_TO = PropertyMailer::AGENT[:email]

  def compose(outgoing_email, recipient_email)
    @body = outgoing_email.body

    if outgoing_email.file.attached?
      blob = outgoing_email.file.blob
      # Read the blob bytes once for THIS message. The fan-out runs one isolated
      # job per recipient (so one failed send never blocks the rest), so each
      # send necessarily downloads its own copy; there is no shared in-process
      # scope to cache across recipients, and passing the bytes through job args
      # would bloat every enqueued job by up to the 10 MB cap. Action Mailer needs
      # the content in hand to build the attachment, so this single read is the
      # minimum work per message.
      attachments[blob.filename.to_s] = {
        mime_type: blob.content_type,
        content: blob.download
      }
    end

    mail(
      to: recipient_email,
      reply_to: REPLY_TO,
      subject: outgoing_email.subject
    )
  end
end
