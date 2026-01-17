class CreateLearningPaths < ActiveRecord::Migration[7.2]
  def change
    create_table :learning_paths do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_material, null: false, foreign_key: true
      t.references :target_node, foreign_key: { to_table: :knowledge_nodes }

      # Path basic info
      t.string :path_name, null: false
      t.string :path_type, default: 'shortest' # shortest, comprehensive, beginner_friendly
      t.string :status, default: 'active' # active, completed, abandoned

      # Path data
      t.json :node_sequence, default: [] # Array of knowledge_node IDs in order
      t.json :edge_sequence, default: [] # Array of knowledge_edge IDs connecting nodes
      t.integer :total_nodes, default: 0
      t.integer :completed_nodes, default: 0
      t.float :completion_percentage, default: 0.0

      # Difficulty and time estimation
      t.integer :difficulty_level, default: 3 # 1-5 scale
      t.integer :estimated_hours, default: 0
      t.integer :actual_hours, default: 0

      # Path quality metrics
      t.float :path_score, default: 0.0 # Overall quality score
      t.float :mastery_requirement, default: 0.8 # Required mastery to proceed
      t.integer :priority, default: 5 # 1-10 scale

      # Progress tracking
      t.datetime :started_at
      t.datetime :last_activity_at
      t.datetime :completed_at
      t.datetime :estimated_completion_at

      # Path metadata
      t.json :mastery_checkpoints, default: {} # Node ID => mastery level
      t.json :learning_statistics, default: {} # Study time, attempts per node
      t.json :alternative_paths, default: [] # Other path options
      t.text :description
      t.text :success_criteria
      t.json :metadata, default: {}

      # Analytics
      t.integer :views_count, default: 0
      t.integer :abandonment_count, default: 0
      t.float :user_satisfaction, default: 0.0

      t.timestamps

      # Indexes
      t.index [:user_id, :study_material_id], name: 'idx_learning_paths_user_material'
      t.index [:user_id, :status], name: 'idx_learning_paths_user_status'
      t.index [:status, :priority], name: 'idx_learning_paths_status_priority'
      t.index :path_type
      t.index :completion_percentage
      t.index :path_score
      t.index :started_at
      t.index :estimated_completion_at
    end
  end
end
