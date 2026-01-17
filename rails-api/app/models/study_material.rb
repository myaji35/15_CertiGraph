class StudyMaterial < ApplicationRecord
  # rails-best-practices: db-counter-cache - Auto-increment/decrement study_materials_count
  belongs_to :study_set, counter_cache: true
  has_many :questions, dependent: :destroy
  has_many :passages, dependent: :destroy
  has_many :document_chunks, dependent: :destroy
  has_many :knowledge_nodes, dependent: :destroy
  has_many :knowledge_edges, through: :knowledge_nodes
  has_many :reviews, dependent: :destroy
  has_many :purchases, dependent: :destroy

  # Epic 5: Tagging associations
  has_many :taggings, as: :taggable, dependent: :destroy
  has_many :tags, through: :taggings

  # Active Storage for PDF files
  has_one_attached :pdf_file

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, if: :is_public?
  validates :category, presence: true, if: :is_public?
  validates :difficulty_level, inclusion: { in: %w[beginner intermediate advanced expert] }, allow_blank: true

  # JSON serialization for extracted_data (Rails 7 syntax)
  serialize :extracted_data, coder: JSON
  # content_metadata is already json type, no need to serialize

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

  # Marketplace methods
  def publish!
    update!(is_public: true, published_at: Time.current)
  end

  def unpublish!
    update!(is_public: false)
  end

  def free?
    price.nil? || price.zero?
  end

  def purchased_by?(user)
    purchases.completed.exists?(user_id: user.id)
  end

  def can_access?(user)
    return true if study_set.user_id == user.id # Owner can always access
    return true if free? && is_public? # Free public materials
    purchased_by?(user) # Check if purchased
  end

  def reviewed_by?(user)
    reviews.exists?(user_id: user.id)
  end

  def rating_distribution
    reviews.group(:rating).count.transform_keys(&:to_i)
  end

  def average_rating_text
    return "평가 없음" if total_reviews.zero?
    "#{avg_rating} / 5.0 (#{total_reviews}개 평가)"
  end

  # === Epic 5: Content Structuring Methods ===

  # Category helpers
  def category_display
    ContentClassificationService.category_name(category) if category
  end

  def difficulty_display
    ContentClassificationService.difficulty_name(difficulty) if difficulty
  end

  # Auto-classify this study material
  def auto_classify!
    service = ContentClassificationService.new(self)
    service.classify
  end

  # Extract metadata
  def extract_metadata!
    service = ContentMetadataService.new(self)
    service.extract_metadata
  end

  # Generate tags automatically
  def auto_tag!
    service = AutoTaggingService.new(self)
    service.generate_tags
  end

  # Full content structuring pipeline
  def structure_content!
    return false unless status == 'completed'

    begin
      auto_classify!
      extract_metadata!
      auto_tag!
      true
    rescue StandardError => e
      Rails.logger.error("Content structuring failed: #{e.message}")
      false
    end
  end

  # Tag management
  def add_tag(tag_name, context: 'manual', relevance_score: 100)
    tag = Tag.find_or_create_by_name(tag_name)
    taggings.find_or_create_by(tag: tag) do |tagging|
      tagging.context = context
      tagging.relevance_score = relevance_score
    end
  end

  def remove_tag(tag_name)
    tag = Tag.find_by(name: tag_name.downcase)
    return false unless tag

    taggings.where(tag: tag).destroy_all
    true
  end

  def tag_names
    tags.pluck(:name)
  end

  def tags_by_context(context)
    tags.joins(:taggings).where(taggings: { context: context, taggable: self })
  end

  # Metadata helpers
  def exam_year
    content_metadata&.dig(:exam_year)
  end

  def exam_round
    content_metadata&.dig(:exam_round)
  end

  def certification_name
    content_metadata&.dig(:certification_name)
  end

  def complexity_score
    content_metadata&.dig(:complexity_score) || 0
  end

  # Search and filter scopes
  scope :published, -> { where(is_public: true) }
  scope :unpublished, -> { where(is_public: false) }
  scope :free, -> { published.where("price = 0 OR price IS NULL") }
  scope :paid, -> { published.where("price > 0") }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_difficulty, ->(difficulty) { where(difficulty_level: difficulty) }
  scope :by_certification, ->(cert) { joins(:study_set).where(study_sets: { certification: cert }) }
  scope :with_min_rating, ->(rating) { where("avg_rating >= ?", rating) }
  scope :popular, -> { order(sales_count: :desc, avg_rating: :desc) }
  scope :top_rated, -> { where("avg_rating >= ?", 4.0).order(avg_rating: :desc) }
  scope :recent, -> { order(published_at: :desc) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }

  # Epic 5: Content structuring scopes
  scope :by_epic5_difficulty, ->(difficulty) { where(difficulty: difficulty) }
  scope :by_year, ->(year) { where("json_extract(content_metadata, '$.exam_year') = ?", year) }
  scope :with_tags, -> { joins(:tags).distinct }
  scope :tagged_with, ->(tag_name) { joins(:tags).where(tags: { name: tag_name.downcase }).distinct }
  scope :easy, -> { where(difficulty: [1, 2]) }
  scope :medium, -> { where(difficulty: 3) }
  scope :hard, -> { where(difficulty: [4, 5]) }
  scope :structured, -> { where.not(category: nil).where.not(difficulty: nil) }
  scope :needs_structuring, -> { where(status: 'completed', category: nil) }

  private

  def set_default_status
    self.status ||= 'pending'
    self.parsing_progress ||= 0
    self.difficulty ||= 3
    self.content_metadata ||= {}
  end
end
