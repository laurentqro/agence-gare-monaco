class PropertyMailer < ApplicationMailer
  # The agent who shares properties with contacts. Surfaced in the email header
  # and used as the Reply-To so prospects reach the negotiator directly.
  AGENT = {
    name: "Adrien Maré",
    email: "adrien@agencegaremonaco.com",
    phone: "+33 6 62 39 20 65"
  }.freeze

  def share_property(property, contact)
    @property = property
    @contact = contact
    @agent = AGENT
    @hero_image = property.photos.first

    mail(
      to: contact&.email || "preview@example.com",
      reply_to: AGENT[:email],
      subject: "#{property.reference} — #{property.title_for(:fr)}"
    )
  end
end
