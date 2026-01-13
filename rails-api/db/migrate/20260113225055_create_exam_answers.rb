class CreateExamAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :exam_answers do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.string :selected_answer
      t.boolean :is_correct
      t.integer :time_spent

      t.timestamps
    end
  end
end
