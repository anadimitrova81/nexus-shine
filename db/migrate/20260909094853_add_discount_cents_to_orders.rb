class AddDiscountCentsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :discount_cents, :integer, default: 0, null: false
  end
end
