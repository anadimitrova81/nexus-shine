class AddWeightToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :weight_grams, :integer, null: false, default: 0
  end
end
