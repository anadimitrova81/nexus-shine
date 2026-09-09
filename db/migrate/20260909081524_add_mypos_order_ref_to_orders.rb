class AddMyposOrderRefToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :mypos_order_ref, :string
  end
end
