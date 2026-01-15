class CreateEmbeddings < ActiveRecord::Migration[7.2]
  def change
    create_table :embeddings do |t|
      t.references :document_chunk, null: false, foreign_key: true
      t.json :vector, null: false, comment: "1536-dimensional embedding from text-embedding-3-small"
      t.float :magnitude, null: false, comment: "L2 norm for similarity calculations"
      t.integer :model_version, default: 1, comment: "Version of the embedding model"
      t.datetime :generated_at, null: false

      t.timestamps
    end

    # document_chunk_id index는 references로 이미 생성됨
    add_index :embeddings, :generated_at
  end
end
