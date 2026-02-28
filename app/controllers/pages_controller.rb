class PagesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def home
    @featured_articles = Article.published.featured.order(published_at: :desc).limit(3)
    set_seo(page_type: :homepage)
  end

  def contact
    set_seo(page_type: :contact)
  end

  def privacy
    set_seo(page_type: :privacy)
  end
end
