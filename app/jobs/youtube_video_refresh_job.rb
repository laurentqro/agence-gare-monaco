class YoutubeVideoRefreshJob < ApplicationJob
  queue_as :default

  def perform
    YoutubeFeedFetcher.refresh
  end
end
