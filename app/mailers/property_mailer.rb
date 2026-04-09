class PropertyMailer < ApplicationMailer
  def share_property(property, contact)
    @property = property
    @contact = contact
    @images = property.photos.limit(4)

    mail(
      to: contact&.email || "preview@example.com",
      subject: "#{property.reference} — #{property.title_for(:fr)}"
    )
  end
end
