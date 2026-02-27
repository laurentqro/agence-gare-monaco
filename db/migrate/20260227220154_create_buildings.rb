class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings do |t|
      t.string :name, null: false
      t.string :name_alt
      t.string :address
      t.references :district, foreign_key: true
      t.string :city
      t.integer :immotoolbox_id

      t.timestamps
    end

    add_index :buildings, :immotoolbox_id, unique: true
  end
end
