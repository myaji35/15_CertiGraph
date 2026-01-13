class RemoveEncryptedPasswordFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :encrypted_password, :string
  end
end
