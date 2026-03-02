require "test_helper"

class YoutubeFeedFetcherTest < ActiveSupport::TestCase
  FEED_URL = "https://www.youtube.com/feeds/videos.xml?channel_id=UC2w6AJOPj37wDZxXjWLRxtg"

  setup do
    WebMock.disable_net_connect!
  end

  teardown do
    WebMock.allow_net_connect!
  end

  test "refresh fetches RSS feed and creates video records" do
    stub_request(:get, FEED_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/xml" },
      body: sample_feed(2)
    )

    assert_difference "YoutubeVideo.count", 2 do
      YoutubeFeedFetcher.refresh
    end

    video = YoutubeVideo.find_by(video_id: "video_0")
    assert_equal "Test Video 0", video.title
    assert_equal "https://i.ytimg.com/vi/video_0/hqdefault.jpg", video.thumbnail_url
    assert_not_nil video.published_at
  end

  test "refresh updates existing videos instead of creating duplicates" do
    YoutubeVideo.create!(video_id: "video_0", title: "Old Title", published_at: 1.day.ago)

    stub_request(:get, FEED_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/xml" },
      body: sample_feed(1)
    )

    assert_no_difference "YoutubeVideo.count" do
      YoutubeFeedFetcher.refresh
    end

    assert_equal "Test Video 0", YoutubeVideo.find_by(video_id: "video_0").title
  end

  test "refresh handles HTTP errors gracefully" do
    stub_request(:get, FEED_URL).to_return(status: 500, body: "Internal Server Error")

    assert_nothing_raised do
      YoutubeFeedFetcher.refresh
    end

    assert_equal 0, YoutubeVideo.count
  end

  test "refresh handles network timeouts gracefully" do
    stub_request(:get, FEED_URL).to_timeout

    assert_nothing_raised do
      YoutubeFeedFetcher.refresh
    end

    assert_equal 0, YoutubeVideo.count
  end

  test "refresh handles malformed XML gracefully" do
    stub_request(:get, FEED_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/xml" },
      body: "<not valid xml<<<"
    )

    assert_nothing_raised do
      YoutubeFeedFetcher.refresh
    end

    assert_equal 0, YoutubeVideo.count
  end

  test "refresh handles connection refused gracefully" do
    stub_request(:get, FEED_URL).to_raise(SocketError.new("Connection refused"))

    assert_nothing_raised do
      YoutubeFeedFetcher.refresh
    end

    assert_equal 0, YoutubeVideo.count
  end

  private

  def sample_feed(count)
    entries = count.times.map do |i|
      <<~ENTRY
        <entry>
          <yt:videoId>video_#{i}</yt:videoId>
          <title>Test Video #{i}</title>
          <published>2026-02-#{28 - i}T12:00:00+00:00</published>
          <media:group>
            <media:thumbnail url="https://i.ytimg.com/vi/video_#{i}/hqdefault.jpg" />
          </media:group>
        </entry>
      ENTRY
    end

    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
            xmlns:media="http://search.yahoo.com/mrss/"
            xmlns="http://www.w3.org/2005/Atom">
        <title>Channel Title</title>
        #{entries.join}
      </feed>
    XML
  end
end
