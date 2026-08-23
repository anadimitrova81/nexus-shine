class AddPaymentToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :payment_method, :string, null: false, default: "cod"
    add_column :orders, :payment_status, :string, null: false, default: "pending"
    add_column :orders, :mypos_ipc_trnref, :string
    add_index :orders, :payment_status
  end
end
