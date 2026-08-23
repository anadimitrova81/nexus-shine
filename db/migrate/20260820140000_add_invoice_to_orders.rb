class AddInvoiceToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :wants_invoice, :boolean, null: false, default: false
    add_column :orders, :invoice_eik, :string
    add_column :orders, :invoice_company, :string
    add_column :orders, :invoice_vat, :string
    add_column :orders, :invoice_mol, :string        # МОЛ (representative)
    add_column :orders, :invoice_address, :string
  end
end
