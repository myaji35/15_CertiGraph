class StudyMaterial < ApplicationRecord
  belongs_to :study_set
  has_many :questions, dependent: :destroy
  has_many :document_chunks, dependent: :destroy
  has_many :knowledge_nodes, dependent: :destroy
  has_many :knowledge_edges, through: :knowledge_nodes

  # Active Storage for PDF files
  has_one_attached :pdf_file

  validates :name, presence: true

  # JSON serialization for extracted_data (Rails 7 syntax)
  serialize :extracted_data, coder: JSON

  enum status: {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }

  after_initialize :set_default_status, if: :new_record?

  def status_display
    case status
    when 'pending'
      '대기중'
    when 'processing'
      '처리중'
    when 'completed'
      '완료'
    when 'failed'
      '실패'
    else
      status
    end
  end

  def title
    name
  end

  def file_name
    pdf_file.attached? ? pdf_file.filename.to_s : 'PDF 파일 없음'
  end

  # 추출된 문제 가져오기
  def extracted_questions
    extracted_data&.dig('questions') || []
  end

  # 총 문제 수
  def total_questions
    questions.count
  end

  # 청킹된 수
  def total_chunks
    extracted_data&.dig('chunks') || 0
  end

  # 처리 완료 여부
  def processing_completed?
    status == 'completed' && questions.any?
  end

  private

  def set_default_status
    self.status ||= 'pending'
    self.parsing_progress ||= 0
  end
end
