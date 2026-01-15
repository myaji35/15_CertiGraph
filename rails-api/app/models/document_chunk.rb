class DocumentChunk < ApplicationRecord
  belongs_to :study_material
  has_one :embedding, dependent: :destroy
  has_many :chunk_questions, dependent: :destroy
  has_many :questions, through: :chunk_questions

  validates :content, :token_count, :chunk_index, :start_position, :end_position, presence: true
  validates :chunk_index, uniqueness: { scope: :study_material_id }

  scope :with_passage, -> { where(has_passage: true) }
  scope :by_index, -> { order(:chunk_index) }

  def embedding_generated?
    embedding.present?
  end

  def with_embedding?
    embedding.present? && embedding.vector.present?
  end

  def text_preview(length = 100)
    content.truncate(length)
  end
end
