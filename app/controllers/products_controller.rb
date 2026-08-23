class ProductsController < ApplicationController
  # The shop grid. Optional ?category= filter and ?sort= ordering.
  def index
    @categories = Category.ordered
    @active_category = Category.find_by(slug: params[:category])
    @sort = params[:sort].presence_in(Product::SORTS.keys) || "name"

    scope = Product.active.includes(:brand, :categories)
    scope = scope.merge(@active_category.products) if @active_category
    @products = scope.merge(Product.sorted_by(@sort))
  end

  def show
    @product = Product.active.includes(:brand, :categories).find_by!(slug: params[:id])
    @related = @product.categories.flat_map { |c| c.products.active.where.not(id: @product.id) }
                        .uniq.first(4)
  end
end
