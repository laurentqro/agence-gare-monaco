module Admin
  class OutgoingEmailsController < BaseController
    # Pre-filled into the body on a fresh compose page, built from the shared
    # agent record so the name/email/phone stay in one place. The leading blank
    # lines put the cursor above the signature so Adrien types his message first.
    SIGNATURE = "\n\n#{PropertyMailer::AGENT[:name]}\n" \
                "#{PropertyMailer::AGENT[:email]}\n" \
                "T: #{PropertyMailer::AGENT[:phone]}".freeze

    def new
      load_recipients
      @outgoing_email ||= OutgoingEmail.new(body: SIGNATURE)
    end

    def create
      @outgoing_email = OutgoingEmail.new(outgoing_email_params)
      recipients = resolve_recipients

      if recipients.empty?
        @outgoing_email.errors.add(:base, t("admin.outgoing_emails.flash.no_recipients"))
        return render_new_with_errors
      end

      @outgoing_email.pending_count = recipients.size
      unless @outgoing_email.save
        return render_new_with_errors
      end

      recipients.each do |email|
        SendOutgoingEmailJob.perform_later(@outgoing_email.id, email)
      end

      redirect_to new_admin_outgoing_email_url,
                  notice: t("admin.outgoing_emails.flash.queued", count: recipients.size)
    end

    private

    def outgoing_email_params
      params.require(:outgoing_email).permit(:subject, :body, :file)
    end

    # Resolves submitted contact_ids to recipient emails. A send may now target a
    # mixed audience (peers and contacts together), so there is no audience cross-
    # filter: any email-bearing contact whose id was submitted is a recipient.
    # Ids that no longer exist or lost their email between page-load and submit
    # are silently dropped (page-load vs submit drift); if that leaves zero, the
    # create path treats it as "no recipients selected". `.distinct` guards against
    # a contact submitted twice from double-counting or double-sending.
    def resolve_recipients
      ids = Array(params[:contact_ids]).reject(&:blank?)
      return [] if ids.empty?

      Contact.with_email.where(id: ids).distinct.pluck(:email)
    end

    def render_new_with_errors
      load_recipients
      render :new, status: :unprocessable_entity
    end

    # Loads both recipient lists, each name-ordered and each narrowed by its own
    # search term. Both are shown at once (stacked), so the compose page can build
    # one email to a mix of peers and contacts. Only email-bearing contacts appear.
    def load_recipients
      @peers_query = params[:peers_q]
      @contacts_query = params[:contacts_q]
      @peers = Contact.peers.with_email.search(@peers_query).order(:last_name, :first_name)
      @contacts = Contact.contacts_only.with_email.search(@contacts_query).order(:last_name, :first_name)
    end
  end
end
