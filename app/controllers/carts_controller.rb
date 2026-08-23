class CartsController < ApplicationController
  def show
  end

  def add
    product = Product.active.find(params[:product_id])
    unless product.in_stock?
      return redirect_back fallback_location: shop_path, alert: "#{product.name} е изчерпан."
    end
    current_cart.add(product, (params[:quantity] || 1).to_i)
    # Never let the cart exceed available stock.
    if current_cart.store[product.id.to_s].to_i > product.stock_quantity
      current_cart.set(product, product.stock_quantity)
    end
    respond_to do |format|
      format.turbo_stream # renders add.turbo_stream.erb (updates cart badge + flash)
      format.html { redirect_back fallback_location: shop_path, notice: "#{product.name} е добавен в количката." }
    end
  end

  def update
    product = Product.find(params[:product_id])
    current_cart.set(product, params[:quantity])
    redirect_to cart_path
  end

  def remove
    product = Product.find(params[:product_id])
    current_cart.remove(product)
    redirect_to cart_path, notice: "Продуктът е премахнат от количката."
  end

  def clear
    current_cart.clear
    redirect_to cart_path, notice: "Количката е изпразнена."
  end
end
