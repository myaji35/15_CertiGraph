class EnhanceTestSessionsForCbt < ActiveRecord::Migration[7.2]
  def change
    # Add pause/resume tracking
    add_column :test_sessions, :paused_at, :datetime
    add_column :test_sessions, :resumed_at, :datetime
    add_column :test_sessions, :total_pause_duration, :integer, default: 0 # in seconds
    add_column :test_sessions, :pause_count, :integer, default: 0
    add_column :test_sessions, :is_paused, :boolean, default: false

    # Add auto-save tracking
    add_column :test_sessions, :last_autosave_at, :datetime
    add_column :test_sessions, :autosave_count, :integer, default: 0

    # Add navigation and statistics
    add_column :test_sessions, :current_question_id, :integer
    add_column :test_sessions, :answer_change_count, :integer, default: 0
    add_column :test_sessions, :bookmark_count, :integer, default: 0
    add_column :test_sessions, :average_time_per_question, :decimal, precision: 10, scale: 2
    add_column :test_sessions, :estimated_completion_time, :datetime

    # Add time tracking per question
    add_column :test_questions, :time_started_at, :datetime
    add_column :test_questions, :time_spent, :integer, default: 0 # in seconds
    add_column :test_questions, :answer_change_count, :integer, default: 0

    # Add indexes for better query performance
    add_index :test_sessions, :is_paused
    add_index :test_sessions, :current_question_id
    add_index :test_sessions, :last_autosave_at
    add_index :test_questions, :time_started_at
  end
end
