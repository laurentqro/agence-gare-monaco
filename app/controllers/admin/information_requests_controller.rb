module Admin
  class InformationRequestsController < BaseController
    before_action :set_submission, only: %i[show update destroy]

    def index
      @filter = params[:filter]
      @submissions = filtered_scope.order(created_at: :desc)

      @counts = {
        all: InformationRequest.count,
        unread: InformationRequest.unread.count,
        enquiry: InformationRequest.where(form_type: "enquiry").count,
        contact: InformationRequest.where(form_type: "contact").count
      }
    end

    def show
      @submission.update_column(:read, true) unless @submission.read?
    end

    def update
      @submission.update(submission_params)
      redirect_to admin_information_requests_url, notice: t("admin.information_requests.flash.updated")
    end

    def destroy
      @submission.destroy
      redirect_to admin_information_requests_url, notice: t("admin.information_requests.flash.deleted")
    end

    private

    def filtered_scope
      case params[:filter]
      when "unread" then InformationRequest.unread
      when "enquiry" then InformationRequest.where(form_type: "enquiry")
      when "contact" then InformationRequest.where(form_type: "contact")
      else InformationRequest.all
      end
    end

    def set_submission
      @submission = InformationRequest.find(params[:id])
    end

    def submission_params
      params.require(:information_request).permit(:read)
    end
  end
end
