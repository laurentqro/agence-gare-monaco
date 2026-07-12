module Admin
  class PropertySharesController < BaseController
    include RecipientLoading

    before_action :set_property

    def new
      prepare_form
      @property_share ||= PropertyShare.new(subject: default_subject)
    end

    def create
      @property_share = @property.property_shares.new(property_share_params)
      contacts = resolve_recipient_contacts
      # pending_count doubles as the recipients check: the model validates it
      # on create, so a blank subject and zero recipients surface together.
      @property_share.pending_count = contacts.size

      return render_new_with_errors unless @property_share.save

      # Warm the brochure cache before the fan-out so N recipient jobs never
      # trigger N identical Typst generations; each job then only downloads
      # the cached blob.
      if @property_share.attach_pdf
        PropertyBrochureCache.ensure_cached(@property, locale: :fr, include_logo: @property_share.include_logo)
      end

      contacts.each do |contact|
        SharePropertyEmailJob.perform_later(@property_share.id, contact.id)
      end

      redirect_to admin_property_url(@property), notice: t("admin.property_shares.flash.shared", count: contacts.size)
    end

    # Returns the share email HTML for the live preview iframe, re-rendered
    # with whatever note the admin has typed so far. POST (not GET) because a
    # long note does not fit in a query string.
    def preview
      render html: preview_html(params[:body]).html_safe, layout: false
    end

    private

    # fetch, not require: a stripped POST with no property_share key must fall
    # through to the normal validation errors (422), not raise a 400.
    def property_share_params
      params.fetch(:property_share, {}).permit(:subject, :body, :attach_pdf, :include_logo)
    end

    def render_new_with_errors
      prepare_form
      render :new, status: :unprocessable_entity
    end

    # Everything the form page needs besides the form object itself: the two
    # recipient lists and the initial email preview (which reflects the typed
    # note when a validation failure re-renders the page).
    def prepare_form
      load_recipients
      @email_preview = preview_html(@property_share&.body)
    end

    # decoded returns a SafeBuffer; coerce to a plain String so the view can
    # HTML-escape it into the iframe srcdoc attribute (otherwise the inline
    # style double-quotes truncate the attribute and the preview is blank).
    def preview_html(note_body)
      PropertyMailer.share_property(@property, nil, body: note_body).body.decoded.to_str
    end

    def default_subject
      PropertyMailer.default_share_subject(@property)
    end

    def set_property
      @property = Property.find(params[:property_id])
    end
  end
end
