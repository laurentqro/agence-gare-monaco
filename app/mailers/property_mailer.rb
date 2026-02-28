class PropertyMailer < ApplicationMailer
  def share_email(property, contact)
    @property = property
    @contact = contact
    @images = property.photos.limit(4)

    mail(
      to: contact.email,
      subject: "#{property.reference} — #{property.title_for(:fr)}"
    )
  end
end
