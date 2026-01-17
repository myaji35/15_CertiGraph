class AddSecurityFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    # Lockable
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    # Trackable
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Confirmable (optional)
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    # Session timeout tracking
    add_column :users, :last_activity_at, :datetime

    # Security alerts
    add_column :users, :security_alerts_enabled, :boolean, default: true
    add_column :users, :suspicious_login_detected, :boolean, default: false

    add_index :users, :unlock_token, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :failed_attempts
    add_index :users, :last_activity_at
  end
end
