class CreateOutgoingEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :outgoing_emails do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :pending_count, null: false, default: 0

      t.timestamps
    end
  end
end
