class AddCoverImageUrlToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :cover_image_url, :string
  end
end
