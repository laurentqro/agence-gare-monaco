module Admin
  class PropertySharesController < BaseController
    include RecipientLoading

    before_action :set_property

    def new
      load_recipients
      @property_share ||= PropertyShare.new(subject: default_subject)
      # decoded returns a SafeBuffer; coerce to a plain String so the view can
      # HTML-escape it into the iframe srcdoc attribute (otherwise the inline
      # style double-quotes truncate the attribute and the preview is blank).
      @email_preview = PropertyMailer.share_property(@property, nil).body.decoded.to_str
    end

    def create
      contact_ids = Array(params[:contact_ids]).reject(&:blank?)

      if contact_ids.empty?
        redirect_to new_admin_property_share_url(@property), alert: t("admin.property_shares.flash.no_contacts_selected")
        return
      end

      contacts = Contact.where(id: contact_ids)
      contacts.each do |contact|
        PropertyMailer.share_property(@property, contact).deliver_now
      end

      redirect_to admin_contacts_url, notice: t("admin.property_shares.flash.shared", count: contacts.size)
    end

    private

    # Matches the auto subject the mailer falls back to, so the prefilled field
    # sends the same email as an untouched one.
    def default_subject
      "#{@property.reference} — #{@property.title_for(:fr)}"
    end

    def set_property
      @property = Property.find(params[:property_id])
    end
  end
end
