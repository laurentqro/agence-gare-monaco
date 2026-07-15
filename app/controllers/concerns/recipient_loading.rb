# Recipient handling shared by the compose-email and property-share pages,
# which both render the stacked audience picker
# (admin/shared/_recipient_list) and resolve its submitted checkboxes.
module RecipientLoading
  extend ActiveSupport::Concern

  # Picker section => contact categories it lists, in display order. Owners
  # and tenants get their own sections; "contacts" holds the rest of our own
  # contacts (unclassified + prospects).
  AUDIENCES = {
    "peers" => %w[peer],
    "owners" => %w[owner],
    "tenants" => %w[tenant],
    "contacts" => %w[contact prospect]
  }.freeze

  private

  # Loads one recipient list per audience section, each name-ordered and each
  # narrowed by its own search term (peers_q, owners_q, …). All are shown at
  # once (stacked), so a page can build one email to a mixed audience. Only
  # email-bearing contacts appear. @selected_contact_ids re-checks the
  # submitted boxes when a validation failure re-renders the page (empty on a
  # fresh GET), so the admin's selection survives the round-trip.
  def load_recipients
    @selected_contact_ids = submitted_contact_ids.map(&:to_s).to_set
    @recipient_sections = AUDIENCES.map do |audience, categories|
      query = params["#{audience}_q"]
      {
        audience: audience,
        query: query,
        query_param: "#{audience}_q",
        recipients: Contact.where(category: categories).with_email
                           .search(query).order(:last_name, :first_name).load
      }
    end
  end

  # Resolves submitted contact_ids to Contact records. A send may target a
  # mixed audience (peers and contacts together), so there is no audience cross-
  # filter: any email-bearing contact whose id was submitted is a recipient.
  # Ids that no longer exist or lost their email between page-load and submit
  # are silently dropped (page-load vs submit drift); if that leaves zero, the
  # caller treats it as "no recipients selected". `.distinct` guards against a
  # contact submitted twice from double-counting or double-sending.
  def resolve_recipient_contacts
    ids = submitted_contact_ids
    return Contact.none if ids.empty?

    Contact.with_email.where(id: ids).distinct
  end

  # The one place the raw contact_ids[] param is parsed: both the re-checked
  # boxes (@selected_contact_ids) and the resolved recipients derive from it,
  # so they cannot drift apart.
  def submitted_contact_ids
    Array(params[:contact_ids]).reject(&:blank?)
  end
end
