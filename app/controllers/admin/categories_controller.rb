module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[edit update destroy]

    def index
      @categories = Category.left_joins(:articles)
        .select("categories.*, COUNT(articles.id) AS articles_count")
        .group("categories.id")
        .order(:slug)
    end

    def new
      @category = Category.new
    end

    def create
      @category = Category.new(category_params)
      generate_slug_if_blank
      if @category.save
        redirect_to admin_categories_url, notice: t("admin.categories.flash.created")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      @category.assign_attributes(category_params)
      if @category.save
        redirect_to admin_categories_url, notice: t("admin.categories.flash.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @category.destroy
      redirect_to admin_categories_url, notice: t("admin.categories.flash.deleted")
    end

    private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:slug, name: I18n.available_locales.map(&:to_s))
    end

    def generate_slug_if_blank
      if @category.slug.blank? && @category.name.is_a?(Hash)
        fr_name = @category.name["fr"].presence || @category.name.values.first
        @category.slug = fr_name.parameterize if fr_name.present?
      end
    end
  end
end
