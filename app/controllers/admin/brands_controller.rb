module Admin
  class BrandsController < BaseController
    before_action :set_brand, only: %i[edit update destroy]

    def index
      @brands = Brand.ordered
    end

    def new
      @brand = Brand.new
    end

    def create
      @brand = Brand.new(brand_params)
      if @brand.save
        redirect_to admin_brands_path, notice: "Марката е създадена."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @brand.update(brand_params)
        redirect_to admin_brands_path, notice: "Марката е обновена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @brand.destroy
      redirect_to admin_brands_path, notice: "Марката е изтрита."
    end

    private

    def set_brand
      @brand = Brand.find(params[:id])
    end

    def brand_params
      params.require(:brand).permit(:name, :slug, :description)
    end
  end
end
