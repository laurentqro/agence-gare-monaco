class CreatePropertyShares < ActiveRecord::Migration[8.1]
  def change
    create_table :property_shares do |t|
      t.references :property, null: false, foreign_key: true
      t.string :subject, null: false
      t.text :body
      t.boolean :attach_pdf, default: false, null: false
      t.boolean :include_logo, default: true, null: false
      t.integer :pending_count, default: 0, null: false
      t.json :sent_contact_ids, default: [], null: false

      t.timestamps
    end
  end
end
