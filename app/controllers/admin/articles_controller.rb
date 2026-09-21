module Admin
  class ArticlesController < BaseController
    include MergesTranslatedColumns

    # JSON columns holding every locale. The admin edits FR only.
    TRANSLATED_COLUMNS = %w[title body meta_description].freeze

    # Per-locale SEO Overrides (title, meta description, Localized Slug). The
    # admin edits every target locale; a blank field removes that override.
    OVERRIDE_COLUMNS = %w[title_overrides meta_description_overrides slugs].freeze

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
        @article.enqueue_post_save_jobs!
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
        @article.enqueue_post_save_jobs!
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
      permitted = params.require(:article).permit(
        :slug, :category_id, :published, :featured, :cover_image_url,
        title: [ :fr ],
        body: [ :fr ],
        meta_description: [ :fr ],
        title_overrides: Article::TARGET_LOCALES,
        meta_description_overrides: Article::TARGET_LOCALES,
        slugs: Article::TARGET_LOCALES
      )

      merge_translated_columns(permitted, @article, TRANSLATED_COLUMNS)
      # Blank override fields clear that locale's override (see the concern).
      merge_translated_columns(permitted, @article, OVERRIDE_COLUMNS, drop_blank: true)
    end

    def set_published_at
      if @article.published? && @article.published_at.nil?
        @article.published_at = Time.current
      end
    end
  end
end
