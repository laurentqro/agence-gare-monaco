class YoutubeVideo < ApplicationRecord
  CHANNEL_ID = "UC2w6AJOPj37wDZxXjWLRxtg".freeze
  CHANNEL_URL = "https://www.youtube.com/channel/#{CHANNEL_ID}".freeze

  validates :video_id, presence: true, uniqueness: true
  validates :title, presence: true
  validates :published_at, presence: true

  scope :latest, ->(n = 4) { order(published_at: :desc).limit(n) }

  def embed_url
    "https://www.youtube-nocookie.com/embed/#{video_id}"
  end
end
