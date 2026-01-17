class AddProfileFieldsToUsers < ActiveRecord::Migration[7.2]
  def change
    # Profile information
    add_column :users, :bio, :text
    add_column :users, :phone_number, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :avatar_url, :string

    # User preferences
    add_column :users, :preferences, :json, default: {}
    add_column :users, :notification_settings, :json, default: {}

    # Login history (stored as JSON array)
    add_column :users, :login_history, :json, default: []

    # Account status
    add_column :users, :account_status, :string, default: 'active'
    add_column :users, :deactivated_at, :datetime
    add_column :users, :deletion_requested_at, :datetime

    # Social links
    add_column :users, :social_links, :json, default: {}

    add_index :users, :phone_number
    add_index :users, :account_status
  end
end
