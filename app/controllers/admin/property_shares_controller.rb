module Admin
  class PropertySharesController < BaseController
    include RecipientLoading

    before_action :set_property

    def new
      prepare_form
      @property_share ||= PropertyShare.new(subject: default_subject)
    end

    def create
      @property_share = PropertyShare.new(property_share_params)
      contacts = resolve_recipient_contacts

      # Both problems surface together in one round-trip: validate first, then
      # stack the recipients error on top (valid? would wipe it otherwise).
      @property_share.valid?
      @property_share.errors.add(:base, t("admin.property_shares.flash.no_contacts_selected")) if contacts.empty?
      return render_new_with_errors if @property_share.errors.any?

      contacts.each do |contact|
        SharePropertyEmailJob.perform_later(
          @property.id, contact.id,
          @property_share.subject, @property_share.body,
          @property_share.attach_pdf, @property_share.include_logo
        )
      end

      redirect_to admin_contacts_url, notice: t("admin.property_shares.flash.shared", count: contacts.size)
    end

    private

    def property_share_params
      params.require(:property_share).permit(:subject, :body, :attach_pdf, :include_logo)
    end

    def render_new_with_errors
      prepare_form
      render :new, status: :unprocessable_entity
    end

    # Everything the form page needs besides the form object itself: the two
    # recipient lists and the static email preview.
    def prepare_form
      load_recipients
      # decoded returns a SafeBuffer; coerce to a plain String so the view can
      # HTML-escape it into the iframe srcdoc attribute (otherwise the inline
      # style double-quotes truncate the attribute and the preview is blank).
      @email_preview = PropertyMailer.share_property(@property, nil).body.decoded.to_str
    end

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
