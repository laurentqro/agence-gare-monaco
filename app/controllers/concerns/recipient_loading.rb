# Recipient handling shared by the compose-email and property-share pages,
# which both render the stacked peers/contacts picker
# (admin/shared/_recipient_list) and resolve its submitted checkboxes.
module RecipientLoading
  extend ActiveSupport::Concern

  private

  # Loads both recipient lists, each name-ordered and each narrowed by its own
  # search term. Both are shown at once (stacked), so a page can build one email
  # to a mix of peers and contacts. Only email-bearing contacts appear.
  def load_recipients
    @peers_query = params[:peers_q]
    @contacts_query = params[:contacts_q]
    @peers = Contact.peers.with_email.search(@peers_query).order(:last_name, :first_name)
    @contacts = Contact.contacts_only.with_email.search(@contacts_query).order(:last_name, :first_name)
  end

  # Resolves submitted contact_ids to Contact records. A send may target a
  # mixed audience (peers and contacts together), so there is no audience cross-
  # filter: any email-bearing contact whose id was submitted is a recipient.
  # Ids that no longer exist or lost their email between page-load and submit
  # are silently dropped (page-load vs submit drift); if that leaves zero, the
  # caller treats it as "no recipients selected". `.distinct` guards against a
  # contact submitted twice from double-counting or double-sending.
  def resolve_recipient_contacts
    ids = Array(params[:contact_ids]).reject(&:blank?)
    return Contact.none if ids.empty?

    Contact.with_email.where(id: ids).distinct
  end
end
