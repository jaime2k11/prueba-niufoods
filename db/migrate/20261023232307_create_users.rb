class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      # Campos mínimos para login por sesión/cookies
      t.string :email, null: false
      t.string :password_digest, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
