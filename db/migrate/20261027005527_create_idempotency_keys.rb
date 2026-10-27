class CreateIdempotencyKeys < ActiveRecord::Migration[7.1]
  def change
    create_table :idempotency_keys do |t|
      t.string :key, null: false
      t.string :request_hash
      t.references :order, null: true, foreign_key: true
      t.integer :status_code
      t.text :response_body
      t.datetime :expires_at, null: false

      t.timestamps
    end
    add_index :idempotency_keys, :key, unique: true
    add_index :idempotency_keys, :expires_at
  end
end
