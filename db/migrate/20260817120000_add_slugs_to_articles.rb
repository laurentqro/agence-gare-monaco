class AddSlugsToArticles < ActiveRecord::Migration[8.1]
  # Per-locale article slugs (SEO audit 0.2). The existing `slug` string column
  # stays as the canonical FR slug and stable lookup key; `slugs` holds the
  # per-locale localised slugs (keyed by locale), mirroring the `title` JSON
  # column. Frozen once backfilled: a later title edit does not move the URL.
  def change
    add_column :articles, :slugs, :json, default: {}, null: false
  end
end
