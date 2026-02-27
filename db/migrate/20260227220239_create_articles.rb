class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.json :title
      t.json :body
      t.string :slug, null: false
      t.references :category, null: false, foreign_key: true
      t.boolean :published, default: false
      t.boolean :featured, default: false
      t.datetime :published_at

      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :published
    add_index :articles, :featured
  end
end
