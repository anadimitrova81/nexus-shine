class AddStockToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :stock_quantity, :integer, null: false, default: 0
    add_column :products, :low_stock_threshold, :integer, null: false, default: 5
    # Guards against decrementing stock twice for the same order.
    add_column :orders, :stock_reduced, :boolean, null: false, default: false
  end
end
