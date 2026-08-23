class AddProformaToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :proforma_number, :bigint
    add_index :orders, :proforma_number, unique: true
    add_column :orders, :proforma_issued_at, :datetime
  end
end
