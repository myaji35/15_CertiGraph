class AddPaymentFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :is_paid, :boolean, default: false
    add_column :users, :valid_until, :datetime
    add_column :users, :subscription_type, :string

    add_index :users, :is_paid
    add_index :users, :valid_until
  end
end
