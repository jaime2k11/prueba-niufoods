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

ActiveRecord::Schema[7.1].define(version: 2026_10_27_005527) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "idempotency_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "request_hash"
    t.bigint "order_id"
    t.integer "status_code"
    t.text "response_body"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_idempotency_keys_on_expires_at"
    t.index ["key"], name: "index_idempotency_keys_on_key", unique: true
    t.index ["order_id"], name: "index_idempotency_keys_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.bigint "unit_price_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_items_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.check_constraint "quantity > 0", name: "order_items_quantity_positive"
    t.check_constraint "unit_price_cents >= 0", name: "order_items_unit_price_cents_non_negative"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "restaurant_id", null: false
    t.integer "order_type", null: false
    t.string "customer_name", null: false
    t.string "customer_phone", null: false
    t.string "delivery_address"
    t.bigint "total_cents", default: 0, null: false
    t.integer "dispatch_status", default: 0, null: false
    t.datetime "dispatched_at"
    t.text "dispatch_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "dispatch_attempts", default: 0, null: false
    t.datetime "last_dispatched_at"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["dispatch_status"], name: "index_orders_on_dispatch_status"
    t.index ["restaurant_id", "created_at"], name: "index_orders_on_restaurant_id_and_created_at"
    t.index ["restaurant_id"], name: "index_orders_on_restaurant_id"
    t.check_constraint "dispatch_status = ANY (ARRAY[0, 1, 2])", name: "orders_dispatch_status_check"
    t.check_constraint "order_type = ANY (ARRAY[0, 1])", name: "orders_order_type_check"
    t.check_constraint "total_cents >= 0", name: "orders_total_cents_non_negative"
  end

  create_table "products", force: :cascade do |t|
    t.string "sku", null: false
    t.string "name", null: false
    t.bigint "price_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.check_constraint "price_cents >= 0", name: "products_price_cents_non_negative"
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_restaurants_on_code", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "idempotency_keys", "orders"
  add_foreign_key "order_items", "orders", on_delete: :cascade
  add_foreign_key "order_items", "products", on_delete: :restrict
  add_foreign_key "orders", "restaurants", on_delete: :restrict
end
