class CreateContactSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :contact_submissions do |t|
      t.string :form_type, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :country
      t.string :subject
      t.text :message, null: false
      t.references :property, foreign_key: true
      t.boolean :read, default: false

      t.timestamps
    end

    add_index :contact_submissions, :form_type
    add_index :contact_submissions, :read
  end
end
