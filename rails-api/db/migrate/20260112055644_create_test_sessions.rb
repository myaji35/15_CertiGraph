class CreateTestSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :test_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_set, null: false, foreign_key: true
      t.string :test_type # practice, mock_exam, review
      t.integer :question_count, default: 20
      t.integer :time_limit # in minutes
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :correct_answers, default: 0
      t.integer :total_answered, default: 0
      t.decimal :score, precision: 5, scale: 2
      t.string :status, default: 'in_progress' # in_progress, completed, abandoned
      t.json :settings # difficulty, categories, etc
      t.json :results # detailed results

      t.timestamps
    end

    add_index :test_sessions, :status
    add_index :test_sessions, [:user_id, :status]
    add_index :test_sessions, [:study_set_id, :status]
  end
end
