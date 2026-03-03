class PagesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def home
    @latest_articles = Article.published.order(published_at: :desc).limit(4)
    @youtube_videos = YoutubeVideo.latest
    @submission = ContactSubmission.new
    set_seo(page_type: :homepage)
  end

  def contact
    @submission = ContactSubmission.new
    set_seo(page_type: :contact)
  end

  def privacy
    set_seo(page_type: :privacy)
  end
end
