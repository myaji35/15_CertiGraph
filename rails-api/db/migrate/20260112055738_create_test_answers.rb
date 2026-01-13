class CreateTestAnswers < ActiveRecord::Migration[7.2]
  def change
    create_table :test_answers do |t|
      t.references :test_question, null: false, foreign_key: true, index: { unique: true }
      t.string :selected_answer # The option selected (①, ②, ③, ④, ⑤)
      t.boolean :is_correct
      t.integer :time_spent # Seconds spent on this question
      t.datetime :answered_at

      t.timestamps
    end
  end
end
