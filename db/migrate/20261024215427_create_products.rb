class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      # SKU único por producto
      t.string :sku, null: false
      t.string :name, null: false
      # Precios en CLP como enteros
      t.bigint :price_cents, null: false, default: 0

      t.timestamps
    end
    add_index :products, :sku, unique: true
    add_check_constraint :products, "price_cents >= 0", name: "products_price_cents_non_negative"
  end
end
