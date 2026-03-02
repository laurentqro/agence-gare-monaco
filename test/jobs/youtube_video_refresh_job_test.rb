require "test_helper"

class YoutubeVideoRefreshJobTest < ActiveJob::TestCase
  FEED_URL = "https://www.youtube.com/feeds/videos.xml?channel_id=UC2w6AJOPj37wDZxXjWLRxtg"

  test "job calls YoutubeFeedFetcher.refresh" do
    stub_request(:get, FEED_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "application/xml" },
      body: <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns:yt="http://www.youtube.com/xml/schemas/2015"
              xmlns:media="http://search.yahoo.com/mrss/"
              xmlns="http://www.w3.org/2005/Atom">
          <title>Channel</title>
          <entry>
            <yt:videoId>job_test_vid</yt:videoId>
            <title>Job Test Video</title>
            <published>2026-02-28T12:00:00+00:00</published>
            <media:group>
              <media:thumbnail url="https://i.ytimg.com/vi/job_test_vid/hqdefault.jpg" />
            </media:group>
          </entry>
        </feed>
      XML
    )

    assert_difference "YoutubeVideo.count", 1 do
      YoutubeVideoRefreshJob.perform_now
    end
  end
end
