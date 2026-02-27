class CreateDistricts < ActiveRecord::Migration[8.1]
  def change
    create_table :districts do |t|
      t.string :name, null: false
      t.string :city, null: false
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.string :slug
      t.integer :immotoolbox_id

      t.timestamps
    end

    add_index :districts, :immotoolbox_id, unique: true
    add_index :districts, :slug, unique: true
  end
end
