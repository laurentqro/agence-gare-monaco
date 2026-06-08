class ExtendContactsForLegacyImport < ActiveRecord::Migration[8.1]
  def up
    add_column :contacts, :company, :string
    add_column :contacts, :address, :string
    add_column :contacts, :city, :string
    add_column :contacts, :postcode, :string
    add_column :contacts, :country, :string
    add_column :contacts, :notes, :text
    add_column :contacts, :legacy_id, :integer

    add_index :contacts, :legacy_id, unique: true

    # Relax the constraints inherited from the public-form era: legacy contacts
    # may have no email (57/92) and no personal name (18/92, e.g. consulates, SCIs).
    remove_index :contacts, :email
    change_column_null :contacts, :email, true
    change_column_null :contacts, :first_name, true
    change_column_null :contacts, :last_name, true
  end

  def down
    change_column_null :contacts, :last_name, false
    change_column_null :contacts, :first_name, false
    change_column_null :contacts, :email, false
    add_index :contacts, :email, unique: true

    remove_index :contacts, :legacy_id
    remove_column :contacts, :legacy_id
    remove_column :contacts, :notes
    remove_column :contacts, :country
    remove_column :contacts, :postcode
    remove_column :contacts, :city
    remove_column :contacts, :address
    remove_column :contacts, :company
  end
end
