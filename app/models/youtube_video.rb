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

  # Embed URL that starts playing immediately — used when a facade thumbnail
  # is clicked, so the user does not have to press play twice.
  def autoplay_embed_url
    "#{embed_url}?autoplay=1"
  end

  # Cookie-free thumbnail for the click-to-load facade. Prefers the stored
  # feed thumbnail, falling back to YouTube's deterministic image CDN
  # (i.ytimg.com sets no cookies, unlike the embed iframe).
  def thumbnail_image_url
    thumbnail_url.presence || "https://i.ytimg.com/vi/#{video_id}/hqdefault.jpg"
  end
end
