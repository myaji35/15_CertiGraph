class CreatePurchases < ActiveRecord::Migration[7.2]
  def change
    create_table :purchases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_material, null: false, foreign_key: true
      t.references :payment, null: true, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.string :status, default: 'pending', null: false
      t.integer :download_count, default: 0
      t.integer :download_limit, default: 5
      t.datetime :purchased_at
      t.datetime :expires_at
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :purchases, [:user_id, :study_material_id], unique: true
    add_index :purchases, :status
    add_index :purchases, :purchased_at
    add_index :purchases, :expires_at
  end
end
