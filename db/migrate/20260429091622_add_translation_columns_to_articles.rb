class AddTranslationColumnsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :translation_source_hash, :string
    add_column :articles, :translations_status, :json, default: {}
  end
end
