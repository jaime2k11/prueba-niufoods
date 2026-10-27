class AddDispatchAttemptsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :dispatch_attempts, :integer, default: 0, null: false
    add_column :orders, :last_dispatched_at, :datetime
  end
end
