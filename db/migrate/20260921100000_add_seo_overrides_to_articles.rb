class AddSeoOverridesToArticles < ActiveRecord::Migration[8.1]
  # Per-locale SEO Overrides. The agency can pin a title and a meta description
  # for one locale without the translator overwriting them on the next French
  # edit. Keyed by locale like the translated `title` / `meta_description`
  # hashes; the slug override lives in the existing `slugs` column.
  def change
    add_column :articles, :title_overrides, :json, default: {}, null: false
    add_column :articles, :meta_description_overrides, :json, default: {}, null: false
  end
end
