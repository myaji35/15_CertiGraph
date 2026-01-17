class Tagging < ApplicationRecord
  # Associations
  belongs_to :tag, counter_cache: :usage_count
  belongs_to :taggable, polymorphic: true

  # Validations
  validates :tag_id, uniqueness: { scope: [:taggable_type, :taggable_id] }
  validates :relevance_score, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }, allow_nil: true

  # Callbacks
  after_create :increment_tag_usage
  after_destroy :decrement_tag_usage

  # Scopes
  scope :by_context, ->(context) { where(context: context) }
  scope :relevant, -> { where('relevance_score >= ?', 50).order(relevance_score: :desc) }
  scope :for_study_materials, -> { where(taggable_type: 'StudyMaterial') }

  # Class methods
  def self.contexts
    distinct.pluck(:context).compact.sort
  end

  def self.average_relevance
    average(:relevance_score).to_f.round(2)
  end

  # Instance methods
  def high_relevance?
    relevance_score && relevance_score >= 75
  end

  def medium_relevance?
    relevance_score && relevance_score >= 50 && relevance_score < 75
  end

  def low_relevance?
    relevance_score && relevance_score < 50
  end

  def relevance_label
    return 'unknown' unless relevance_score

    case relevance_score
    when 75..100
      'high'
    when 50...75
      'medium'
    when 0...50
      'low'
    else
      'unknown'
    end
  end

  private

  def increment_tag_usage
    tag.increment_usage! if tag
  end

  def decrement_tag_usage
    tag.decrement_usage! if tag
  end
end
