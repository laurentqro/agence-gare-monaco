class CreateYoutubeVideos < ActiveRecord::Migration[8.1]
  def change
    create_table :youtube_videos do |t|
      t.string :video_id, null: false
      t.string :title, null: false
      t.string :thumbnail_url
      t.datetime :published_at, null: false

      t.timestamps
    end

    add_index :youtube_videos, :video_id, unique: true
  end
end
