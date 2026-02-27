class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.string :reference, null: false
      t.json :title
      t.json :description
      t.integer :price
      t.string :currency, default: "EUR"
      t.integer :service_charges
      t.boolean :service_charges_included, default: false
      t.string :transaction_type, null: false
      t.string :property_type, null: false
      t.string :subtype
      t.string :country, null: false
      t.string :city, null: false
      t.references :district, foreign_key: true
      t.references :building, foreign_key: true
      t.string :address
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.integer :floor
      t.integer :num_rooms
      t.integer :num_bedrooms
      t.integer :num_bathrooms
      t.integer :num_parkings
      t.integer :num_cellars
      t.decimal :living_area, precision: 10, scale: 2
      t.decimal :total_area, precision: 10, scale: 2
      t.decimal :terrace_area, precision: 10, scale: 2
      t.decimal :land_area, precision: 10, scale: 2
      t.decimal :garden_area, precision: 10, scale: 2
      t.boolean :furnished, default: false
      t.boolean :published, default: false
      t.boolean :off_market, default: false
      t.boolean :featured, default: false
      t.boolean :exclusivity, default: false
      t.boolean :shared_exclusivity, default: false
      t.string :video_url
      t.string :virtual_tour_url
      t.boolean :has_360_tour, default: false
      t.integer :immotoolbox_id
      t.datetime :synced_at
      t.boolean :manually_edited, default: false

      t.timestamps
    end

    add_index :properties, :reference, unique: true
    add_index :properties, :immotoolbox_id, unique: true
    add_index :properties, :transaction_type
    add_index :properties, :country
    add_index :properties, :published
    add_index :properties, :off_market
    add_index :properties, :featured
  end
end
