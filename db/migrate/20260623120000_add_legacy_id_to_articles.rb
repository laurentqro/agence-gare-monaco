class AddLegacyIdToArticles < ActiveRecord::Migration[8.1]
  # The old CMS exposed articles at /{locale}/(article|post)/{id}/{slug}.
  # We persist that old numeric id so legacy redirects can resolve an article
  # by id (stable) rather than by slug (regenerated from the new title, so it
  # drifts from the old URL's slug).
  def change
    add_column :articles, :legacy_id, :integer
    add_index :articles, :legacy_id, unique: true
  end
end
