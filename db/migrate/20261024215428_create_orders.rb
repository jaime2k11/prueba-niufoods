class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :restaurant, null: false, foreign_key: { on_delete: :restrict }
      # Tipo de orden: 0=pickup, 1=delivery
      t.integer :order_type, null: false
      t.string :customer_name, null: false
      t.string :customer_phone, null: false
      t.string :delivery_address
      # Total calculado en servidor desde items
      t.bigint :total_cents, null: false, default: 0
      # Estado del pedido: 0=pending, 1=sent, 2=error
      t.integer :dispatch_status, null: false, default: 0
      t.datetime :dispatched_at
      t.text :dispatch_error

      t.timestamps
    end
    add_index :orders, :dispatch_status
    add_index :orders, :created_at
    add_index :orders, [:restaurant_id, :created_at]
    add_check_constraint :orders, "order_type IN (0,1)", name: "orders_order_type_check"
    add_check_constraint :orders, "dispatch_status IN (0,1,2)", name: "orders_dispatch_status_check"
    add_check_constraint :orders, "total_cents >= 0", name: "orders_total_cents_non_negative"
  end
end
