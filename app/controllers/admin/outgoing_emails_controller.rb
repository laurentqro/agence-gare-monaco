module Admin
  class OutgoingEmailsController < BaseController
    AUDIENCES = %w[peers contacts].freeze

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

    # Resolves submitted contact_ids to [email, name] pairs, keeping only
    # contacts that still exist, belong to the submitted audience, and have a
    # non-nil email. Out-of-audience / missing / now-email-less ids are silently
    # dropped (page-load vs submit drift); if that leaves zero, the create path
    # treats it as "no recipients selected".
    def resolve_recipients
      ids = Array(params[:contact_ids]).reject(&:blank?)
      return [] if ids.empty?

      audience_scope(Contact.with_email.where(id: ids)).pluck(:email)
    end

    def render_new_with_errors
      load_recipients
      render :new, status: :unprocessable_entity
    end

    # Recipients are email-bearing contacts of the chosen audience, name-ordered.
    # Mirrors PropertySharesController#new (audience filter then search), minus
    # sorting — this page deliberately has no sortable columns.
    def load_recipients
      @audience = AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @query = params[:q]

      emailable = Contact.with_email
      @recipients = audience_scope(emailable)
                      .search(@query)
                      .order(:last_name, :first_name)
    end

    def audience_scope(relation)
      @audience ||= AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @audience == "contacts" ? relation.contacts_only : relation.peers
    end
  end
end
