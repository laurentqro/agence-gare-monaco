module Admin
  class CategoriesController < BaseController
    before_action :set_category, only: %i[edit update destroy]

    def index
      @categories = Category.left_joins(:articles)
        .select("categories.*, COUNT(articles.id) AS articles_count")
        .group("categories.id")
        .order(:name)
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
      params.require(:category).permit(:name, :slug)
    end

    def generate_slug_if_blank
      if @category.slug.blank? && @category.name.present?
        @category.slug = @category.name.parameterize
      end
    end
  end
end
