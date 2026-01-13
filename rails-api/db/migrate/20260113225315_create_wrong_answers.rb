class CreateWrongAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :wrong_answers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :study_set, null: false, foreign_key: true
      t.string :selected_answer
      t.integer :attempt_count
      t.datetime :last_attempted_at

      t.timestamps
    end
  end
end
