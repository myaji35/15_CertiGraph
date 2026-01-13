class CreateExamSessions < ActiveRecord::Migration[7.2]
  def change
    create_table :exam_sessions do |t|
      t.references :study_set, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :status
      t.datetime :started_at
      t.datetime :completed_at
      t.integer :total_questions
      t.integer :answered_questions
      t.integer :correct_answers
      t.integer :time_limit
      t.float :score
      t.string :exam_type

      t.timestamps
    end
  end
end
