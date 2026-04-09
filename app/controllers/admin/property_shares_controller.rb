module Admin
  class PropertySharesController < BaseController
    before_action :set_property

    def new
      @contacts = Contact.order(:last_name, :first_name)
      @email_preview = PropertyMailer.share_property(@property, nil).body.decoded
    end

    def create
      contact_ids = Array(params[:contact_ids]).reject(&:blank?)

      if contact_ids.empty?
        redirect_to new_admin_property_share_url(@property), alert: t("admin.property_shares.flash.no_contacts_selected")
        return
      end

      contacts = Contact.where(id: contact_ids)
      contacts.each do |contact|
        PropertyMailer.share_property(@property, contact).deliver_now
      end

      redirect_to admin_contacts_url, notice: t("admin.property_shares.flash.shared", count: contacts.size)
    end

    private

    def set_property
      @property = Property.find(params[:property_id])
    end
  end
end
