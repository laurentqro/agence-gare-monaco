class AddMetaDescriptionToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :meta_description, :json
  end
end
