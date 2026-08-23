class AddShippingToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :shipping_method, :string      # "office" | "address"
    add_column :orders, :shipping_cents, :integer, null: false, default: 0
    add_column :orders, :shipping_site_id, :integer
    add_column :orders, :shipping_office_id, :integer
    add_column :orders, :shipping_city, :string
    add_column :orders, :shipping_label, :string        # human-readable destination
  end
end
