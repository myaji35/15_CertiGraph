class CreateAbTests < ActiveRecord::Migration[7.2]
  def change
    create_table :ab_tests do |t|
      t.string :name, null: false
      t.text :description
      t.string :test_type, null: false # 'algorithm', 'ui', 'recommendation', 'learning_path'
      t.string :status, default: 'draft' # draft, running, paused, completed, cancelled

      # Test configuration
      t.json :variants, default: {} # { control: {}, treatment_a: {}, treatment_b: {} }
      t.float :traffic_allocation, default: 1.0 # 0.0 - 1.0, percentage of users in test
      t.integer :sample_size_target

      # Targeting
      t.json :targeting_criteria, default: {} # user segments, study materials, etc.

      # Duration
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :min_duration_days, default: 7
      t.integer :max_duration_days, default: 30

      # Metrics
      t.json :primary_metrics, default: [] # ['accuracy_improvement', 'engagement', 'completion_rate']
      t.json :secondary_metrics, default: []

      # Results
      t.json :results, default: {} # Detailed results per variant
      t.float :confidence_level, default: 0.0 # 0.0 - 1.0
      t.float :p_value
      t.string :winner_variant
      t.boolean :is_significant, default: false

      # Metadata
      t.references :created_by, foreign_key: { to_table: :users }
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :ab_tests, :name
    add_index :ab_tests, :status
    add_index :ab_tests, :test_type
    add_index :ab_tests, [:status, :started_at]
  end
end
