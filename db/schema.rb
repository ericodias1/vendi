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

ActiveRecord::Schema[8.1].define(version: 2026_01_22_125304) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_configs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.jsonb "additional_settings", default: {}
    t.boolean "auto_send_payment_link", default: false
    t.boolean "card_enabled", default: true
    t.boolean "cash_enabled", default: true
    t.datetime "created_at", null: false
    t.boolean "credit_enabled", default: false
    t.decimal "daily_goal", precision: 10, scale: 2, default: "0.0"
    t.text "enabled_colors", default: [], array: true
    t.text "enabled_sizes", default: [], array: true
    t.boolean "fiado_enabled"
    t.decimal "monthly_goal", precision: 10, scale: 2
    t.boolean "pix_enabled", default: true
    t.boolean "require_customer", default: false
    t.integer "stock_alert_threshold", default: 3
    t.boolean "stock_alerts_enabled", default: true
    t.datetime "updated_at", null: false
    t.decimal "weekly_goal", precision: 10, scale: 2
    t.index ["account_id"], name: "index_account_configs_on_account_id", unique: true
  end

  create_table "accounts", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "logo_url"
    t.string "name", null: false
    t.datetime "onboarding_completed_at"
    t.string "slug", null: false
    t.string "store_type"
    t.string "timezone", default: "America/Sao_Paulo"
    t.datetime "updated_at", null: false
    t.string "whatsapp"
    t.index ["active"], name: "index_accounts_on_active"
    t.index ["slug"], name: "index_accounts_on_slug", unique: true
  end

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

  create_table "customers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.string "city"
    t.string "complement"
    t.string "cpf"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.datetime "discarded_at"
    t.string "email"
    t.datetime "last_purchase_at"
    t.string "name", null: false
    t.string "neighborhood"
    t.string "number"
    t.text "observations"
    t.string "phone"
    t.string "state"
    t.string "street"
    t.integer "total_purchases", default: 0
    t.decimal "total_spent", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.string "zipcode"
    t.index ["account_id"], name: "index_customers_on_account_id"
    t.index ["active"], name: "index_customers_on_active"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
  end

  create_table "payments", force: :cascade do |t|
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "card_last_digits"
    t.datetime "created_at", null: false
    t.integer "installments"
    t.jsonb "metadata", default: {}
    t.string "method", null: false
    t.datetime "paid_at"
    t.text "pix_code"
    t.bigint "sale_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["method"], name: "index_payments_on_method"
    t.index ["sale_id"], name: "index_payments_on_sale_id", unique: true
    t.index ["status"], name: "index_payments_on_status"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.decimal "base_price", precision: 10, scale: 2
    t.string "brand"
    t.string "category"
    t.string "color"
    t.decimal "cost_price", precision: 10, scale: 2
    t.datetime "created_at", null: false
    t.jsonb "custom_fields", default: {}
    t.datetime "deleted_at"
    t.text "description"
    t.datetime "discarded_at"
    t.string "material"
    t.string "name", null: false
    t.integer "position"
    t.string "size"
    t.string "sku"
    t.integer "stock_quantity", default: 0, null: false
    t.string "supplier_code"
    t.datetime "updated_at", null: false
    t.index ["account_id", "sku"], name: "index_products_on_account_id_and_sku", unique: true, where: "(sku IS NOT NULL)"
    t.index ["account_id"], name: "index_products_on_account_id"
    t.index ["active"], name: "index_products_on_active"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
  end

  create_table "sale_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.string "product_color"
    t.bigint "product_id", null: false
    t.string "product_name", null: false
    t.string "product_size"
    t.string "product_sku"
    t.integer "quantity", default: 1, null: false
    t.bigint "sale_id", null: false
    t.decimal "subtotal", precision: 10, scale: 2, null: false
    t.decimal "total_amount", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_sale_items_on_product_id"
    t.index ["sale_id"], name: "index_sale_items_on_sale_id"
  end

  create_table "sales", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.decimal "discount_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "discount_percentage", precision: 5, scale: 2
    t.text "observations"
    t.datetime "payment_link_sent_at"
    t.string "payment_link_token"
    t.string "sale_number", null: false
    t.string "status", default: "draft", null: false
    t.decimal "subtotal", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.integer "total_items", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["account_id"], name: "index_sales_on_account_id"
    t.index ["created_at"], name: "index_sales_on_created_at"
    t.index ["customer_id"], name: "index_sales_on_customer_id"
    t.index ["sale_number"], name: "index_sales_on_sale_number", unique: true
    t.index ["status"], name: "index_sales_on_status"
    t.index ["user_id"], name: "index_sales_on_user_id"
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}
    t.string "movement_type", null: false
    t.text "observations"
    t.bigint "product_id"
    t.integer "quantity_after", null: false
    t.integer "quantity_before", null: false
    t.integer "quantity_change", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["account_id"], name: "index_stock_movements_on_account_id"
    t.index ["created_at"], name: "index_stock_movements_on_created_at"
    t.index ["movement_type"], name: "index_stock_movements_on_movement_type"
    t.index ["product_id"], name: "index_stock_movements_on_product_id"
    t.index ["user_id"], name: "index_stock_movements_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.string "password_digest", null: false
    t.datetime "password_reset_sent_at"
    t.string "password_reset_token"
    t.string "phone"
    t.string "role", default: "employee"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["active"], name: "index_users_on_active"
    t.index ["email", "account_id"], name: "index_users_on_email_and_account_id", unique: true
  end

  add_foreign_key "account_configs", "accounts"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "accounts"
  add_foreign_key "payments", "sales"
  add_foreign_key "products", "accounts"
  add_foreign_key "sale_items", "products"
  add_foreign_key "sale_items", "sales"
  add_foreign_key "sales", "accounts"
  add_foreign_key "sales", "customers"
  add_foreign_key "sales", "users"
  add_foreign_key "stock_movements", "accounts"
  add_foreign_key "stock_movements", "products"
  add_foreign_key "stock_movements", "users"
  add_foreign_key "users", "accounts"
end
