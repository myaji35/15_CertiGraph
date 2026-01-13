class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :encrypted_password
      t.string :name
      t.integer :role

      t.timestamps
    end
    add_index :users, :email, unique: true
  end
end
