require "test_helper"

class YoutubeVideoTest < ActiveSupport::TestCase
  test "validates presence of video_id" do
    video = YoutubeVideo.new(title: "Test", published_at: Time.current)
    assert_not video.valid?
    assert_includes video.errors[:video_id], "can't be blank"
  end

  test "validates presence of title" do
    video = YoutubeVideo.new(video_id: "abc123", published_at: Time.current)
    assert_not video.valid?
    assert_includes video.errors[:title], "can't be blank"
  end

  test "validates presence of published_at" do
    video = YoutubeVideo.new(video_id: "abc123", title: "Test")
    assert_not video.valid?
    assert_includes video.errors[:published_at], "can't be blank"
  end

  test "validates uniqueness of video_id" do
    YoutubeVideo.create!(video_id: "abc123", title: "First", published_at: Time.current)
    duplicate = YoutubeVideo.new(video_id: "abc123", title: "Second", published_at: Time.current)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:video_id], "has already been taken"
  end

  test "latest returns videos ordered by published_at descending" do
    old = YoutubeVideo.create!(video_id: "old", title: "Old Video", published_at: 2.days.ago)
    new_vid = YoutubeVideo.create!(video_id: "new", title: "New Video", published_at: 1.day.ago)

    result = YoutubeVideo.latest
    assert_equal [ new_vid, old ], result.to_a
  end

  test "latest defaults to 4 videos" do
    5.times do |i|
      YoutubeVideo.create!(video_id: "vid#{i}", title: "Video #{i}", published_at: i.days.ago)
    end

    assert_equal 4, YoutubeVideo.latest.count
  end

  test "latest accepts custom limit" do
    3.times do |i|
      YoutubeVideo.create!(video_id: "vid#{i}", title: "Video #{i}", published_at: i.days.ago)
    end

    assert_equal 2, YoutubeVideo.latest(2).count
  end

  test "embed_url returns youtube-nocookie embed URL" do
    video = YoutubeVideo.new(video_id: "dQw4w9WgXcQ")
    assert_equal "https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ", video.embed_url
  end

  test "CHANNEL_ID is set" do
    assert_equal "UC2w6AJOPj37wDZxXjWLRxtg", YoutubeVideo::CHANNEL_ID
  end

  test "CHANNEL_URL points to YouTube channel" do
    assert_equal "https://www.youtube.com/channel/UC2w6AJOPj37wDZxXjWLRxtg", YoutubeVideo::CHANNEL_URL
  end
end
