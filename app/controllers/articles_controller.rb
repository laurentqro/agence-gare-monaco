class ArticlesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  def index
    @articles = Article.published.includes(:category).order(published_at: :desc)
    @category = nil
    set_seo(page_type: :articles)
  end

  def show
    @category = Category.find_by(slug: params[:slug])
    if @category
      @articles = @category.articles.published.order(published_at: :desc)
      set_seo(page_type: :articles)
      render :index
    else
      @article = Article.published.find_by!(slug: params[:slug])
      set_seo(page_type: :article, article: @article)
    end
  end
end
