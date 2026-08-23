class AddSpecsToProducts < ActiveRecord::Migration[8.1]
  def change
    # WooCommerce "Допълнителна информация" attributes, stored as an ordered
    # list of [label, value] pairs (JSON array) so display order is preserved.
    add_column :products, :specs, :jsonb, null: false, default: []
  end
end
