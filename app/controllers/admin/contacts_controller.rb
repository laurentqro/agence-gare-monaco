module Admin
  class ContactsController < BaseController
    include Sortable

    SORT_COLUMNS = %w[last_name first_name company email phone].freeze

    before_action :set_contact, only: %i[edit update destroy]

    def index
      @filter = params[:filter]
      @query = params[:q]

      scope = filtered_scope.search(@query)
      @contacts = sort_scope(scope, columns: SORT_COLUMNS, default: "last_name")

      @counts = {
        all: Contact.count,
        contacts: Contact.contacts_only.count,
        peers: Contact.peers.count
      }
    end

    def new
      @contact = Contact.new
    end

    def create
      @contact = Contact.new(contact_params)
      if @contact.save
        redirect_to admin_contacts_url, notice: flash_notice(:created)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @contact.assign_attributes(contact_params)
      if @contact.save
        redirect_to admin_contacts_url, notice: flash_notice(:updated)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @contact.destroy
      redirect_to admin_contacts_url, notice: flash_notice(:deleted)
    end

    private

    # Picks the confrère-specific flash message when the record is a peer,
    # falling back to the generic contact wording otherwise.
    def flash_notice(action)
      key = @contact.peer? ? "peer_#{action}" : action
      t("admin.contacts.flash.#{key}")
    end

    def filtered_scope
      case params[:filter]
      when "peers" then Contact.peers
      when "contacts" then Contact.contacts_only
      else Contact.all
      end
    end

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(
        :first_name, :last_name, :email, :phone,
        :company, :address, :city, :postcode, :country, :notes, :peer
      )
    end
  end
end
