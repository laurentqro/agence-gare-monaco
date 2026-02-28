class ArticlesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

  def index
    @articles = Article.published.includes(:category).order(published_at: :desc)
    @category = nil
  end

  def show
    @category = Category.find_by(slug: params[:slug])
    if @category
      @articles = @category.articles.published.order(published_at: :desc)
      render :index
    else
      @article = Article.published.find_by!(slug: params[:slug])
    end
  end
end
