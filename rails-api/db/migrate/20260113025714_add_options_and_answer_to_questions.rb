class AddOptionsAndAnswerToQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :options, :json
    add_column :questions, :answer, :string
    add_column :questions, :topic, :string
    add_column :questions, :question_number, :integer

    add_index :questions, :topic
    add_index :questions, :difficulty
  end
end
