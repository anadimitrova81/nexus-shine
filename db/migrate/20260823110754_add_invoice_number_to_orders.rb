class AddInvoiceNumberToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :invoice_number, :bigint
    add_index :orders, :invoice_number, unique: true
    add_column :orders, :invoice_issued_at, :datetime
  end
end
