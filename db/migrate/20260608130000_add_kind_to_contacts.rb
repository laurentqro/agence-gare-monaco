class AddKindToContacts < ActiveRecord::Migration[8.1]
  def up
    add_column :contacts, :kind, :string, null: false, default: "client"
    add_index :contacts, :kind

    # Partners and clients carry separate legacy ID spaces, so legacy_id is only
    # unique within a kind.
    remove_index :contacts, :legacy_id
    add_index :contacts, [:kind, :legacy_id], unique: true
  end

  def down
    remove_index :contacts, [:kind, :legacy_id]
    add_index :contacts, :legacy_id, unique: true
    remove_index :contacts, :kind
    remove_column :contacts, :kind
  end
end
