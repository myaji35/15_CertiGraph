class CreateSubscriptions < ActiveRecord::Migration[7.2]
  def change
    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :payment, null: false, foreign_key: true
      t.string :plan_type, null: false, default: 'season_pass'
      t.integer :price, null: false
      t.datetime :starts_at, null: false
      t.datetime :expires_at, null: false
      t.boolean :is_active, default: true
      t.string :status, default: 'active'

      t.timestamps
    end

    add_index :subscriptions, :status
    add_index :subscriptions, :is_active
    add_index :subscriptions, [:user_id, :is_active]
  end
end
