class CreateDocumentChunks < ActiveRecord::Migration[7.2]
  def change
    create_table :document_chunks do |t|
      t.references :study_material, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :token_count, default: 0
      t.integer :chunk_index, null: false
      t.integer :start_position, null: false
      t.integer :end_position, null: false
      t.boolean :has_passage, default: false
      t.text :passage_context

      t.timestamps
    end

    add_index :document_chunks, [:study_material_id, :chunk_index], unique: true
  end
end
