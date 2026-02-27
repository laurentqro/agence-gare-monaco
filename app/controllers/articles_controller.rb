class ArticlesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

  def index
  end

  def show
    @category = Category.find_by(slug: params[:slug])
    if @category
      render :index
    else
      @article = Article.find_by!(slug: params[:slug])
    end
  end
end
