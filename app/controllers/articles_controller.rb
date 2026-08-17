class ArticlesController < ApplicationController
  include Localizable
  include SeoConfigurable
  allow_unauthenticated_access

  before_action :initialize_information_request

  def index
    @articles = Article.published.includes(:category).order(published_at: :desc)
    @category = nil
    set_seo(page_type: :articles)
  end

  def show
    @category = Category.find_by_localized_slug(params[:slug], I18n.locale)
    if @category
      @articles = @category.articles.published.order(published_at: :desc)
      set_seo(page_type: :articles, category: @category)
      render :index
    else
      @article = Article.published.find_by_localized_slug(params[:slug], I18n.locale)
      raise ActiveRecord::RecordNotFound unless @article

      # Slugs are per-locale (SEO audit 0.2). If the URL carries a non-canonical
      # slug for this locale (e.g. an old shared FR slug indexed under /en),
      # 301 to the locale's canonical slug so authority consolidates on one URL.
      canonical_slug = @article.slug_for(I18n.locale)
      if params[:slug] != canonical_slug
        prefix = I18n.locale == I18n.default_locale ? "" : "/#{I18n.locale}"
        articles_segment = I18n.t("routes.articles")
        redirect_to "#{prefix}/#{articles_segment}/#{canonical_slug}", status: :moved_permanently
        return
      end

      set_seo(page_type: :article, article: @article)
    end
  end

  private

  def initialize_information_request
    @submission = InformationRequest.new
  end
end
