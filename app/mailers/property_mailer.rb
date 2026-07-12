class PropertyMailer < ApplicationMailer
  # The agent who shares properties with contacts. Surfaced in the email header
  # and used as the Reply-To so prospects reach the negotiator directly.
  AGENT = {
    name: "Adrien Maré",
    email: "adrien@agencegaremonaco.com",
    phone: "+33 6 62 39 20 65"
  }.freeze

  # The auto subject used when the admin does not override it. Also prefilled
  # into the share form, so an untouched field sends the same email as a blank
  # one; keep it as the single source for both.
  def self.default_share_subject(property)
    "#{property.reference} — #{property.title_for(:fr)}"
  end

  def share_property(property, contact, subject: nil, body: nil, attach_pdf: false, include_logo: true)
    @property = property
    @contact = contact
    @agent = AGENT
    @hero_image = property.photos.first
    @personal_message = body

    if attach_pdf
      attachments[property.brochure_filename] = {
        mime_type: "application/pdf",
        content: PropertyBrochureCache.fetch(property, locale: :fr, include_logo: include_logo)
      }
    end

    mail(
      to: contact&.email || "preview@example.com",
      reply_to: AGENT[:email],
      subject: subject.presence || self.class.default_share_subject(property)
    )
  end
end
