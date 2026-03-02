class YoutubeFeedFetcher
  FEED_URL = "https://www.youtube.com/feeds/videos.xml?channel_id=#{YoutubeVideo::CHANNEL_ID}".freeze

  def self.refresh
    new.refresh
  end

  def refresh
    entries = fetch_entries
    return unless entries

    entries.each do |entry|
      video_id = entry.at("videoId")&.text
      next unless video_id

      record = YoutubeVideo.find_or_initialize_by(video_id: video_id)
      record.update!(
        title: entry.at("title")&.text,
        thumbnail_url: entry.at("thumbnail")&.[]("url"),
        published_at: entry.at("published")&.text
      )
    end
  end

  private

  def fetch_entries
    uri = URI(FEED_URL)
    response = Net::HTTP.get_response(uri)

    return nil unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::XML(response.body)
    doc.remove_namespaces!
    doc.css("entry")
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError => e
    Rails.logger.error("YoutubeFeedFetcher: Failed to fetch feed — #{e.message}")
    nil
  rescue Nokogiri::XML::SyntaxError => e
    Rails.logger.error("YoutubeFeedFetcher: Failed to parse feed — #{e.message}")
    nil
  end
end
