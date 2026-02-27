class CreatePropertyImages < ActiveRecord::Migration[8.1]
  def change
    create_table :property_images do |t|
      t.references :property, null: false, foreign_key: true
      t.string :remote_url, null: false
      t.string :thumb_url
      t.string :small_url
      t.string :medium_url
      t.string :large_url
      t.integer :position, default: 0
      t.boolean :is_plan, default: false
      t.integer :immotoolbox_id

      t.timestamps
    end

    add_index :property_images, [:property_id, :position]
    add_index :property_images, :immotoolbox_id, unique: true
  end
end
