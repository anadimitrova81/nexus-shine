module Admin
  class ProductsController < BaseController
    before_action :set_product, only: %i[edit update destroy]

    def index
      @products = Product.ordered.includes(:brand, :categories)
    end

    def new
      @product = Product.new(active: true)
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_products_path, notice: "Продуктът е създаден."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Продуктът е обновен."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.destroy
      redirect_to admin_products_path, notice: "Продуктът е изтрит."
    end

    private

    def set_product
      @product = Product.find_by(slug: params[:id]) || Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :slug, :brand_id, :price_eur, :size, :weight_kg, :stock_quantity, :low_stock_threshold,
        :short_description, :description, :specs_text,
        :featured, :best_seller, :active, :position, :image,
        category_ids: [],
      )
    end
  end
end
