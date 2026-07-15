# Replaces the boolean `contacts.peer` with a single-select `category`
# (contact / prospect / peer / owner / tenant). Categories are mutually
# exclusive, and every category except "peer" still counts as one of our own
# contacts. Legacy IDs keep their two separate ID spaces (confrères vs
# everyone else), enforced with partial unique indexes now that the boolean
# partition column is gone.
class ReplacePeerWithCategoryOnContacts < ActiveRecord::Migration[8.1]
  def up
    add_column :contacts, :category, :string, null: false, default: "contact"
    execute "UPDATE contacts SET category = 'peer' WHERE peer = TRUE"

    remove_index :contacts, name: "index_contacts_on_peer_and_legacy_id"
    remove_index :contacts, name: "index_contacts_on_peer"
    remove_column :contacts, :peer

    add_index :contacts, :category
    add_index :contacts, :legacy_id, unique: true,
              where: "category = 'peer'",
              name: "index_contacts_on_legacy_id_for_peers"
    add_index :contacts, :legacy_id, unique: true,
              where: "category != 'peer'",
              name: "index_contacts_on_legacy_id_for_non_peers"
  end

  def down
    add_column :contacts, :peer, :boolean, null: false, default: false
    execute "UPDATE contacts SET peer = TRUE WHERE category = 'peer'"

    remove_index :contacts, name: "index_contacts_on_legacy_id_for_peers"
    remove_index :contacts, name: "index_contacts_on_legacy_id_for_non_peers"
    remove_index :contacts, :category
    remove_column :contacts, :category

    add_index :contacts, [ :peer, :legacy_id ], unique: true
    add_index :contacts, :peer
  end
end
