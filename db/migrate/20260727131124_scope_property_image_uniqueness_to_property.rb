class ScopePropertyImageUniquenessToProperty < ActiveRecord::Migration[8.1]
  # A building shot shared by several properties needs one row per property,
  # because position and is_plan describe the image's role within a property.
  # The old global unique index forced a single row whose ownership ping-ponged
  # between properties on every sync pass.
  def change
    remove_index :property_images, :immotoolbox_id, unique: true
    add_index :property_images, [ :property_id, :immotoolbox_id ], unique: true
  end
end
