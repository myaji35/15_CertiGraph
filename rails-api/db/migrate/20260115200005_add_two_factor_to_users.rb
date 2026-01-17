class AddTwoFactorToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :consumed_timestep, :integer
    add_column :users, :otp_backup_codes, :text
    add_column :users, :otp_required_for_login, :boolean, default: false

    add_index :users, :encrypted_otp_secret, unique: true
  end
end
