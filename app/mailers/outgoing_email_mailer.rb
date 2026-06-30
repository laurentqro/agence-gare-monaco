class OutgoingEmailMailer < ApplicationMailer
  # Replies reach Adrien while the verified agency address stays the From (keeps
  # Brevo/DKIM alignment). Matches PropertyMailer.
  REPLY_TO = "adrien@agencegaremonaco.com".freeze

  def compose(outgoing_email, recipient_email, recipient_name)
    @body = outgoing_email.body
    @recipient_name = recipient_name

    if outgoing_email.file.attached?
      blob = outgoing_email.file.blob
      attachments[blob.filename.to_s] = {
        mime_type: blob.content_type,
        content: outgoing_email.file.download
      }
    end

    mail(
      to: recipient_email,
      reply_to: REPLY_TO,
      subject: outgoing_email.subject
    )
  end
end
