module Admin
  class InformationRequestRepliesController < BaseController
    before_action :set_information_request
    before_action :refuse_undeliverable_address

    def new
      @information_request.mark_read!
      draft = ReplyDraft.new(@information_request)
      @outgoing_email = OutgoingEmail.new(subject: draft.subject, body: draft.body)
    end

    def create
      @outgoing_email = OutgoingEmail.new(outgoing_email_params.merge(pending_count: 1))
      return render :new, status: :unprocessable_entity unless @outgoing_email.save

      @information_request.update!(replied_at: Time.current)
      SendOutgoingEmailJob.perform_later(@outgoing_email.id, @information_request.email)
      redirect_to admin_information_request_url(@information_request),
                  notice: t("admin.information_requests.flash.replied", name: @information_request.name)
    end

    private

    def set_information_request
      @information_request = InformationRequest.find(params[:information_request_id])
    end

    def refuse_undeliverable_address
      return if @information_request.deliverable_email?

      redirect_to admin_information_request_url(@information_request),
                  alert: t("admin.information_requests.flash.undeliverable", email: @information_request.email)
    end

    def outgoing_email_params
      params.require(:outgoing_email).permit(:subject, :body, :file)
    end
  end
end
