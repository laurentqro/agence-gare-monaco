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

    TRANSLATED_COLUMNS = %w[title body meta_description].freeze

    def article_params
      permitted = params.require(:article).permit(
        :slug, :category_id, :published, :featured, :cover_image_url,
        title: [ :fr ],
        body: [ :fr ],
        meta_description: [ :fr ]
      )

      merge_translated_columns(permitted)
    end

    # The form only submits the French value, but assigning it would replace the
    # whole JSON column and destroy the eight translated locales. Merge instead:
    # the translator cannot always rebuild them (API outage, spend cap).
    def merge_translated_columns(permitted)
      TRANSLATED_COLUMNS.each do |column|
        submitted = permitted[column]
        next if submitted.nil?

        existing = @article&.public_send(column) || {}
        permitted[column] = existing.merge(submitted.to_h)
      end

      permitted
    end

    def set_published_at
      if @article.published? && @article.published_at.nil?
        @article.published_at = Time.current
      end
    end
  end
end
