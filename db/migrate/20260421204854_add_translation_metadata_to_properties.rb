class AddTranslationMetadataToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :translation_source_hash, :string
    add_column :properties, :translations_status, :json, default: {}
    remove_column :properties, :manually_edited, :boolean, default: false
  end
end
