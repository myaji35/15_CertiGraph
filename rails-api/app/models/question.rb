class Question < ApplicationRecord
  belongs_to :study_material
  has_many :test_questions, dependent: :destroy

  validates :content, presence: true

  # JSON column은 자동으로 serialize됨 (Rails 7 + SQLite JSON 타입)
  # serialize :options, coder: JSON  # 이건 필요 없음!

  scope :by_topic, ->(topic) { where(topic: topic) }
  scope :by_difficulty, ->(level) { where(difficulty: level) }
  scope :random, -> { order(Arel.sql('RANDOM()')) }

  # 벡터 임베딩을 JSON으로 저장/로드
  def embedding
    JSON.parse(embedding_json) if embedding_json.present?
  end

  def embedding=(vector)
    self.embedding_json = vector.to_json if vector.present?
  end

  # 옵션 랜덤 셔플링
  def randomized_options
    return {} unless options.present?

    # options가 Hash 형태로 저장된 경우
    # { "①" => "답안1", "②" => "답안2", ... }
    options.to_a.shuffle.to_h
  end

  # 정답 텍스트 가져오기
  def correct_answer_text
    options[answer] if options && answer
  end

  # 포맷된 옵션 반환
  def formatted_options
    return {} unless options.present?
    options
  end
end
