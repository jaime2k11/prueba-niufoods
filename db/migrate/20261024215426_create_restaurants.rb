class CreateRestaurants < ActiveRecord::Migration[7.1]
  def change
    create_table :restaurants do |t|
      # Código único por tienda para despachar al simulador
      t.string :code, null: false
      t.string :name, null: false

      t.timestamps
    end
    add_index :restaurants, :code, unique: true
  end
end
