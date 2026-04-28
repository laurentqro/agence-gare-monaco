class PagesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def home
    @latest_articles = Article.published.order(published_at: :desc).limit(9)
    @youtube_videos = YoutubeVideo.latest(9)
    set_seo(page_type: :homepage)
  end

  def contact
    @submission = ContactSubmission.new
    set_seo(page_type: :contact)
  end

  def privacy
    set_seo(page_type: :privacy)
  end

  def gestion
    @submission = ContactSubmission.new
    set_seo(page_type: :gestion)
  end

  def vendre
    @submission = ContactSubmission.new
    set_seo(page_type: :vendre)
  end

  def faq
    set_seo(page_type: :faq)
  end

  TEAM_MEMBERS = {
    "pierre-mare" => { key: "pierre", name: "Pierre Maré", image: "team/pierre.jpg" },
    "adrien-mare" => { key: "adrien", name: "Adrien Maré", image: "team/adrien.jpg" },
    "josiane-alesi" => { key: "josiane", name: "Josiane Alesi", image: "team/josiane.jpg" }
  }.freeze

  def team_member
    @member = TEAM_MEMBERS[params[:member]]
    raise ActionController::RoutingError, "Not Found" unless @member
    set_seo(page_type: :team_member, member: @member)
  end
end
