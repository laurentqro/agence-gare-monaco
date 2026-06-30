module Admin
  class OutgoingEmailsController < BaseController
    AUDIENCES = %w[peers contacts].freeze

    def new
      load_recipients
    end

    private

    # Recipients are email-bearing contacts of the chosen audience, name-ordered.
    # Mirrors PropertySharesController#new (audience filter then search), minus
    # sorting — this page deliberately has no sortable columns.
    def load_recipients
      @audience = AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @query = params[:q]

      emailable = Contact.where.not(email: nil)
      @recipients = audience_scope(emailable)
                      .search(@query)
                      .order(:last_name, :first_name)
    end

    def audience_scope(relation)
      @audience == "contacts" ? relation.contacts_only : relation.peers
    end
  end
end
