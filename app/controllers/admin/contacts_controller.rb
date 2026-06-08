module Admin
  class ContactsController < BaseController
    include Sortable

    SORT_COLUMNS = %w[last_name first_name company email phone].freeze

    before_action :set_contact, only: %i[edit update destroy]

    def index
      @contacts = sort_scope(Contact.all, columns: SORT_COLUMNS, default: "last_name")
    end

    def new
      @contact = Contact.new
    end

    def create
      @contact = Contact.new(contact_params)
      if @contact.save
        redirect_to admin_contacts_url, notice: t("admin.contacts.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @contact.assign_attributes(contact_params)
      if @contact.save
        redirect_to admin_contacts_url, notice: t("admin.contacts.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @contact.destroy
      redirect_to admin_contacts_url, notice: t("admin.contacts.flash.deleted")
    end

    private

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(
        :first_name, :last_name, :email, :phone,
        :company, :address, :city, :postcode, :country, :notes
      )
    end
  end
end
