class CreateTestQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :test_questions do |t|
      t.references :test_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :question_number # Order in the test
      t.json :shuffled_options # Randomized option order
      t.boolean :is_marked, default: false # Marked for review
      t.boolean :is_answered, default: false

      t.timestamps
    end

    add_index :test_questions, [:test_session_id, :question_number]
  end
end
