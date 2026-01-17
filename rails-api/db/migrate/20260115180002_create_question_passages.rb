class CreateQuestionPassages < ActiveRecord::Migration[7.2]
  def change
    create_table :question_passages do |t|
      t.references :question, null: false, foreign_key: true
      t.references :passage, null: false, foreign_key: true
      t.boolean :is_primary, default: false
      t.integer :relevance_score, default: 100

      t.timestamps
    end

    add_index :question_passages, [:question_id, :passage_id], unique: true
    add_index :question_passages, [:passage_id, :is_primary]
  end
end
