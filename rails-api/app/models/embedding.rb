class Embedding < ApplicationRecord
  belongs_to :document_chunk

  validates :vector, :magnitude, :generated_at, presence: true
  validates :vector, array: true, if: -> { vector.is_a?(Array) }

  scope :recent, -> { order(generated_at: :desc) }
  scope :by_model_version, ->(version) { where(model_version: version) }

  # 벡터를 배열로 변환 (JSON에서 로드된 경우)
  def vector_array
    case vector
    when Array
      vector
    when String
      JSON.parse(vector)
    else
      []
    end
  end

  # L2 유사도 계산
  def similarity_to(other_vector)
    return 0.0 if vector_array.blank? || other_vector.blank?

    vec1 = vector_array
    vec2 = other_vector.is_a?(Embedding) ? other_vector.vector_array : other_vector

    return 0.0 if vec1.size != vec2.size

    # 코사인 유사도 계산
    dot_product = vec1.zip(vec2).sum { |a, b| a * b }
    dot_product / (magnitude || 1.0) / (calculate_magnitude(vec2))
  end

  private

  def calculate_magnitude(vector)
    Math.sqrt(vector.sum { |v| v ** 2 })
  end
end
