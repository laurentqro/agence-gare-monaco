module Admin
  class OutgoingEmailsController < BaseController
    include RecipientLoading

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

    def resolve_recipients
      resolve_recipient_contacts.pluck(:email)
    end

    def render_new_with_errors
      load_recipients
      render :new, status: :unprocessable_entity
    end
  end
end
