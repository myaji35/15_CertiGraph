class Tag < ApplicationRecord
  # Associations
  has_many :taggings, dependent: :destroy
  has_many :study_materials, through: :taggings, source: :taggable, source_type: 'StudyMaterial'

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :usage_count, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_save :normalize_name
  after_create :initialize_metadata
  after_destroy :cleanup_orphaned_taggings

  # Note: metadata is json type, no need to serialize

  # Scopes
  scope :popular, -> { where('usage_count > ?', 0).order(usage_count: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }
  scope :alphabetical, -> { order(:name) }

  # Class methods
  def self.find_or_create_by_name(name, attributes = {})
    normalized_name = name.to_s.strip.downcase
    find_or_create_by(name: normalized_name) do |tag|
      tag.assign_attributes(attributes)
    end
  end

  def self.most_used(limit = 10)
    popular.limit(limit)
  end

  def self.for_context(context)
    joins(:taggings).where(taggings: { context: context }).distinct
  end

  # Instance methods
  def increment_usage!
    increment!(:usage_count)
  end

  def decrement_usage!
    decrement!(:usage_count) if usage_count > 0
  end

  def display_name
    name.titleize
  end

  # Returns all study materials tagged with this tag
  def tagged_study_materials
    study_materials.where('taggings.taggable_type = ?', 'StudyMaterial')
  end

  # Statistics
  def tagging_stats
    {
      total_taggings: taggings.count,
      study_materials_count: study_materials.count,
      avg_relevance: taggings.average(:relevance_score).to_f.round(2),
      contexts: taggings.pluck(:context).uniq.compact
    }
  end

  private

  def normalize_name
    self.name = name.to_s.strip.downcase if name.present?
  end

  def initialize_metadata
    self.metadata ||= {}
    update_column(:metadata, metadata) if metadata_changed?
  end

  def cleanup_orphaned_taggings
    # Taggings are destroyed by dependent: :destroy, but this is a safety check
    Tagging.where(tag_id: id).delete_all
  end
end
