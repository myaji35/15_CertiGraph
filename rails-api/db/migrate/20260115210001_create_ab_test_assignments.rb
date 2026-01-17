class CreateAbTestAssignments < ActiveRecord::Migration[7.2]
  def change
    create_table :ab_test_assignments do |t|
      t.references :ab_test, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :variant, null: false # 'control', 'treatment_a', 'treatment_b', etc.

      # Tracking
      t.datetime :assigned_at, null: false
      t.datetime :first_interaction_at
      t.datetime :last_interaction_at
      t.integer :interaction_count, default: 0

      # Conversion tracking
      t.boolean :converted, default: false
      t.datetime :converted_at
      t.json :conversion_data, default: {}

      # Metrics
      t.json :metrics, default: {} # Store specific metrics for this user

      t.timestamps
    end

    add_index :ab_test_assignments, [:ab_test_id, :user_id], unique: true
    add_index :ab_test_assignments, :variant
    add_index :ab_test_assignments, :converted
  end
end
