class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: { on_delete: :cascade }
      t.references :product, null: false, foreign_key: { on_delete: :restrict }
      t.integer :quantity, null: false
      # Precio copiado desde el producto al momento de crear el item
      t.bigint :unit_price_cents, null: false, default: 0

      t.timestamps
    end
    add_index :order_items, [:order_id, :product_id], unique: true
    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "unit_price_cents >= 0", name: "order_items_unit_price_cents_non_negative"
  end
end
