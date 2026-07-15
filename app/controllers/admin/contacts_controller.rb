module Admin
  class ContactsController < BaseController
    include Sortable

    SORT_COLUMNS = %w[last_name first_name company email phone].freeze

    # Index filter param => contact category. "contacts" is the unclassified
    # default bucket, not all non-peers.
    FILTERS = {
      "contacts" => "contact",
      "prospects" => "prospect",
      "peers" => "peer",
      "owners" => "owner",
      "tenants" => "tenant"
    }.freeze

    before_action :set_contact, only: %i[edit update destroy]

    def index
      @filter = params[:filter]
      @query = params[:q]

      scope = filtered_scope.search(@query)
      @contacts = sort_scope(scope, columns: SORT_COLUMNS, default: "last_name")

      category_counts = Contact.group(:category).count
      @counts = { all: category_counts.values.sum }
      FILTERS.each do |filter, category|
        @counts[filter.to_sym] = category_counts.fetch(category, 0)
      end
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

    # Names the contact's category in the flash message (confrère, prospect,
    # propriétaire, locataire); the plain contact category uses the generic
    # wording.
    def flash_notice(action)
      key = @contact.category == "contact" ? action : "#{@contact.category}_#{action}"
      t("admin.contacts.flash.#{key}")
    end

    def filtered_scope
      category = FILTERS[params[:filter]]
      category ? Contact.where(category: category) : Contact.all
    end

    def set_contact
      @contact = Contact.find(params[:id])
    end

    def contact_params
      params.require(:contact).permit(
        :first_name, :last_name, :email, :phone,
        :company, :address, :city, :postcode, :country, :notes, :category
      )
    end
  end
end
