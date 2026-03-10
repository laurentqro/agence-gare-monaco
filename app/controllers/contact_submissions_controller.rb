class ContactSubmissionsController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def create
    # Honeypot check: if the hidden "website" field is filled, silently reject
    if params[:website].present?
      redirect_to redirect_path_after_submission
      return
    end

    @submission = ContactSubmission.new(submission_params)
    @submission.form_type = @submission.property_id.present? ? "enquiry" : "contact"

    if @submission.save
      deliver_email(@submission)
      redirect_to redirect_path_after_submission, flash: { notice: t("contact_form.success") }
    else
      if @submission.property_id.present?
        load_property_data
        render "properties/show", status: :unprocessable_entity
      elsif params[:return_to].in?(%w[gestion vendre])
        set_seo(page_type: params[:return_to].to_sym)
        render "pages/#{params[:return_to]}", status: :unprocessable_entity
      else
        set_seo(page_type: :contact)
        render "pages/contact", status: :unprocessable_entity
      end
    end
  end

  private

  def submission_params
    params.require(:contact_submission).permit(:name, :email, :phone, :country, :subject, :message, :property_id)
  end

  def redirect_path_after_submission
    if @submission&.property_id.present? || params.dig(:contact_submission, :property_id).present?
      property = @submission&.property || Property.find_by(id: params.dig(:contact_submission, :property_id))
      helpers.locale_property_path(property) if property
    elsif params[:return_to] == "gestion"
      helpers.locale_gestion_path
    elsif params[:return_to] == "vendre"
      helpers.locale_vendre_path
    else
      helpers.locale_contact_path
    end
  end

  def deliver_email(submission)
    if submission.form_type == "enquiry"
      ContactMailer.enquiry_email(submission).deliver_now
    else
      ContactMailer.contact_email(submission).deliver_now
    end
  end

  def load_property_data
    @property = Property.includes(:district, :building, :property_images, property_documents: { file_attachment: :blob }).find(@submission.property_id)
    @photos = @property.photos
    @plans = @property.plans
    @documents = @property.property_documents.select { |d| d.file.attached? }
    @similar_properties = Property.publicly_visible
      .where(transaction_type: @property.transaction_type)
      .where.not(id: @property.id)
    @similar_properties = @similar_properties.where(district: @property.district) if @property.district.present?
    @similar_properties = @similar_properties.includes(:property_images, :district).limit(3)
    set_seo(page_type: :property, property: @property)
  end
end
