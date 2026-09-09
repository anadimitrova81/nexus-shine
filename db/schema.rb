# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_09_211111) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admin_accounts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_brands_on_slug", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "categories_products", id: false, force: :cascade do |t|
    t.bigint "category_id", null: false
    t.bigint "product_id", null: false
    t.index ["category_id", "product_id"], name: "index_categories_products_on_category_id_and_product_id", unique: true
    t.index ["product_id"], name: "index_categories_products_on_product_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "product_name", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "address", null: false
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.string "customer_name", null: false
    t.integer "discount_cents", default: 0, null: false
    t.string "email", null: false
    t.string "invoice_address"
    t.string "invoice_company"
    t.string "invoice_eik"
    t.datetime "invoice_issued_at"
    t.string "invoice_mol"
    t.bigint "invoice_number"
    t.string "invoice_vat"
    t.string "mypos_ipc_trnref"
    t.string "mypos_order_ref"
    t.text "note"
    t.string "payment_method", default: "cod", null: false
    t.string "payment_status", default: "pending", null: false
    t.string "phone", null: false
    t.string "postal_code"
    t.datetime "proforma_issued_at"
    t.bigint "proforma_number"
    t.integer "shipping_cents", default: 0, null: false
    t.string "shipping_city"
    t.string "shipping_label"
    t.string "shipping_method"
    t.integer "shipping_office_id"
    t.integer "shipping_site_id"
    t.string "status", default: "pending", null: false
    t.boolean "stock_reduced", default: false, null: false
    t.integer "total_cents", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "wants_invoice", default: false, null: false
    t.index ["invoice_number"], name: "index_orders_on_invoice_number", unique: true
    t.index ["payment_status"], name: "index_orders_on_payment_status"
    t.index ["proforma_number"], name: "index_orders_on_proforma_number", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.boolean "best_seller", default: false, null: false
    t.bigint "brand_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "featured", default: false, null: false
    t.integer "low_stock_threshold", default: 5, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.string "short_description"
    t.string "size"
    t.string "sku"
    t.string "slug", null: false
    t.jsonb "specs", default: [], null: false
    t.integer "stock_quantity", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "weight_grams", default: 0, null: false
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["slug"], name: "index_products_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "products", "brands"
end
