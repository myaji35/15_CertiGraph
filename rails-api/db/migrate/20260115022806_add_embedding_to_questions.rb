class AddEmbeddingToQuestions < ActiveRecord::Migration[7.2]
  def change
    add_column :questions, :embedding, :vector, limit: 1536 unless column_exists?(:questions, :embedding)
    add_column :questions, :embedding_generated_at, :datetime unless column_exists?(:questions, :embedding_generated_at)

    # 임베딩 컬럼에 인덱스 추가 (벡터 검색용)
    # Note: pgvector 확장이 필요하며, SQLite에서는 무시됨
    # add_index :questions, :embedding, using: :ivfflat, opclass: :vector_cosine_ops
  end
end
