class AddTermsAgreementToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :terms_agreed, :boolean
    add_column :users, :privacy_agreed, :boolean
    add_column :users, :marketing_agreed, :boolean
  end
end
