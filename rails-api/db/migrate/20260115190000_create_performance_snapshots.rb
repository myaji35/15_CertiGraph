class CreatePerformanceSnapshots < ActiveRecord::Migration[7.2]
  def change
    create_table :performance_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_set, foreign_key: true
      t.date :snapshot_date, null: false
      t.string :period_type, default: 'daily' # daily, weekly, monthly

      # Overall Performance Metrics
      t.float :overall_mastery_level, default: 0.0
      t.float :overall_accuracy, default: 0.0
      t.integer :total_attempts, default: 0
      t.integer :total_correct, default: 0
      t.float :completion_percentage, default: 0.0

      # Node Status Counts
      t.integer :mastered_nodes_count, default: 0
      t.integer :learning_nodes_count, default: 0
      t.integer :weak_nodes_count, default: 0
      t.integer :untested_nodes_count, default: 0

      # Time-based Metrics
      t.integer :total_study_minutes, default: 0
      t.integer :avg_session_minutes, default: 0
      t.integer :study_sessions_count, default: 0

      # Performance Trends (vs previous period)
      t.float :mastery_change, default: 0.0
      t.float :accuracy_change, default: 0.0
      t.integer :attempts_change, default: 0

      # Subject/Chapter Performance (JSON)
      t.json :subject_breakdown, default: {}
      t.json :chapter_breakdown, default: {}
      t.json :concept_breakdown, default: {}

      # Learning Patterns
      t.integer :morning_study_minutes, default: 0   # 6-12
      t.integer :afternoon_study_minutes, default: 0 # 12-18
      t.integer :evening_study_minutes, default: 0   # 18-24
      t.integer :night_study_minutes, default: 0     # 0-6

      t.float :morning_accuracy, default: 0.0
      t.float :afternoon_accuracy, default: 0.0
      t.float :evening_accuracy, default: 0.0
      t.float :night_accuracy, default: 0.0

      # Predictions
      t.float :predicted_exam_score, default: 0.0
      t.integer :estimated_days_to_mastery, default: 0
      t.float :goal_achievement_probability, default: 0.0

      # Comparative Metrics
      t.float :percentile_rank, default: 0.0
      t.float :avg_mastery_vs_others, default: 0.0

      # Additional Statistics
      t.json :top_strengths, default: []     # Array of top 5 strong concepts
      t.json :top_weaknesses, default: []    # Array of top 5 weak concepts
      t.json :recent_improvements, default: []
      t.json :study_streak_data, default: {}

      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :performance_snapshots, [:user_id, :snapshot_date]
    add_index :performance_snapshots, [:user_id, :study_set_id, :snapshot_date]
    add_index :performance_snapshots, [:snapshot_date, :period_type]
    add_index :performance_snapshots, :overall_mastery_level
    add_index :performance_snapshots, :completion_percentage
  end
end
