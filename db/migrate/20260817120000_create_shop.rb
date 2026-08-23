class CreateShop < ActiveRecord::Migration[8.1]
  def change
    create_table :brands do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :products do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :brand, foreign_key: true
      t.integer :price_cents, null: false, default: 0        # in EUR cents
      t.string :size                                          # e.g. "20 кг", "1 L"
      t.string :short_description
      t.text :description
      t.string :sku
      t.boolean :featured, null: false, default: false
      t.boolean :best_seller, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
      t.index :slug, unique: true
    end

    create_join_table :categories, :products do |t|
      t.index [:category_id, :product_id], unique: true
      t.index :product_id
    end

    create_table :orders do |t|
      t.string :customer_name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.string :address, null: false
      t.string :city, null: false
      t.string :postal_code
      t.text :note
      t.string :status, null: false, default: "pending"
      t.integer :total_cents, null: false, default: 0
      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, foreign_key: true
      t.string :product_name, null: false
      t.integer :unit_price_cents, null: false, default: 0
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end
  end
end
