module Admin
  class ContactSubmissionsController < BaseController
    before_action :set_submission, only: %i[show update destroy]

    def index
      @filter = params[:filter]
      @submissions = filtered_scope.order(created_at: :desc)

      @counts = {
        all: ContactSubmission.count,
        unread: ContactSubmission.unread.count,
        enquiry: ContactSubmission.where(form_type: "enquiry").count,
        contact: ContactSubmission.where(form_type: "contact").count
      }
    end

    def show
      @submission.update_column(:read, true) unless @submission.read?
    end

    def update
      @submission.update(submission_params)
      redirect_to admin_contact_submissions_url, notice: t("admin.contact_submissions.flash.updated")
    end

    def destroy
      @submission.destroy
      redirect_to admin_contact_submissions_url, notice: t("admin.contact_submissions.flash.deleted")
    end

    private

    def filtered_scope
      case params[:filter]
      when "unread" then ContactSubmission.unread
      when "enquiry" then ContactSubmission.where(form_type: "enquiry")
      when "contact" then ContactSubmission.where(form_type: "contact")
      else ContactSubmission.all
      end
    end

    def set_submission
      @submission = ContactSubmission.find(params[:id])
    end

    def submission_params
      params.require(:contact_submission).permit(:read)
    end
  end
end
