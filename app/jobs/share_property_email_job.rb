class SharePropertyEmailJob < ApplicationJob
  queue_as :default

  def perform(property_id, contact_id, subject, body, attach_pdf, include_logo)
    property = Property.find_by(id: property_id)
    contact = Contact.find_by(id: contact_id)
    return if property.nil? || contact.nil?

    PropertyMailer.share_property(
      property, contact,
      subject: subject, body: body,
      attach_pdf: attach_pdf, include_logo: include_logo
    ).deliver_now
  end
end
