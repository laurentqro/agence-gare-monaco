class AddDescriptionToYoutubeVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :youtube_videos, :description, :text
  end
end
