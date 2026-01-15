class ChunkQuestion < ApplicationRecord
  belongs_to :document_chunk
  belongs_to :question

  validates :document_chunk_id, :question_id, presence: true
  validates :question_id, uniqueness: { scope: :document_chunk_id }
end
