class CreateChunkQuestions < ActiveRecord::Migration[7.2]
  def change
    create_table :chunk_questions do |t|
      t.references :document_chunk, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true

      t.timestamps
    end

    add_index :chunk_questions, [:document_chunk_id, :question_id], unique: true
  end
end
