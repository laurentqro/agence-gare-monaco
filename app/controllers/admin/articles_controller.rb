module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: %i[edit update destroy]
    before_action :set_categories, only: %i[new create edit update]

    def index
      @articles = Article.includes(:category).order(created_at: :desc)
    end

    def new
      @article = Article.new
    end

    def create
      @article = Article.new(article_params)
      set_published_at
      if @article.save
        redirect_to admin_articles_url, notice: t("admin.articles.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @article.assign_attributes(article_params)
      set_published_at
      if @article.save
        redirect_to admin_articles_url, notice: t("admin.articles.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy
      redirect_to admin_articles_url, notice: t("admin.articles.flash.deleted")
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def set_categories
      @categories = Category.order(:name)
    end

    def article_params
      params.require(:article).permit(
        :slug, :category_id, :published, :featured, :cover_image_url,
        title: I18n.available_locales.map(&:to_s),
        body: I18n.available_locales.map(&:to_s)
      )
    end

    def set_published_at
      if @article.published? && @article.published_at.nil?
        @article.published_at = Time.current
      end
    end
  end
end
