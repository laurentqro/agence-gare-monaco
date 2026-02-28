class ContactMailer < ApplicationMailer
  def contact_email(submission)
    @submission = submission
    mail(
      to: "info@agencegaremonaco.com",
      reply_to: submission.email,
      subject: "Contact: #{submission.subject}"
    )
  end

  def enquiry_email(submission)
    @submission = submission
    @property = submission.property
    mail(
      to: "info@agencegaremonaco.com",
      reply_to: submission.email,
      subject: "Enquiry: #{@property.reference} — #{@property.title_for(:fr)}"
    )
  end
end
