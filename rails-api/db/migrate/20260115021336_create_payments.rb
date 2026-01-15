class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_id, null: false
      t.string :payment_key
      t.integer :amount, null: false
      t.string :currency, default: 'KRW'
      t.string :status, default: 'pending'
      t.string :method
      t.string :card_company
      t.string :card_number
      t.datetime :approved_at
      t.text :failure_code
      t.text :failure_message
      t.json :metadata

      t.timestamps
    end

    add_index :payments, :order_id, unique: true
    add_index :payments, :payment_key
    add_index :payments, :status
  end
end
