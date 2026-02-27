class CreatePropertyDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :property_documents do |t|
      t.references :property, null: false, foreign_key: true
      t.string :label

      t.timestamps
    end
  end
end
