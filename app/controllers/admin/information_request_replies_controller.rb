module Admin
  class InformationRequestRepliesController < BaseController
    before_action :set_information_request

    def new
      @information_request.mark_read!
      draft = ReplyDraft.new(@information_request)
      @outgoing_email = OutgoingEmail.new(subject: draft.subject, body: draft.body)
    end

    def create
      @outgoing_email = OutgoingEmail.new(outgoing_email_params.merge(pending_count: 1))
      return render :new, status: :unprocessable_entity unless @outgoing_email.save

      SendOutgoingEmailJob.perform_later(@outgoing_email.id, @information_request.email)
      @information_request.update!(replied_at: Time.current)
      redirect_to admin_information_request_url(@information_request),
                  notice: t("admin.information_requests.flash.replied", name: @information_request.name)
    end

    private

    def set_information_request
      @information_request = InformationRequest.find(params[:information_request_id])
    end

    def outgoing_email_params
      params.require(:outgoing_email).permit(:subject, :body, :file)
    end
  end
end
