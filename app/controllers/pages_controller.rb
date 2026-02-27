class PagesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

  def home
    @featured_articles = Article.published.featured.order(published_at: :desc).limit(3)
  end

  def contact
  end

  def privacy
  end
end
