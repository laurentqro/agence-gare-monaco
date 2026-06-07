class AddIntroToProperties < ActiveRecord::Migration[8.1]
  def change
    add_column :properties, :intro, :json
  end
end
