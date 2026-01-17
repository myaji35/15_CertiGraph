# app/models/dashboard_widget.rb
class DashboardWidget < ApplicationRecord
  belongs_to :user

  # Widget types
  WIDGET_TYPES = %w[
    progress
    recent_scores
    weakness_analysis
    goal_achievement
    study_time
    ranking
    upcoming_exams
    recommendations
    achievements
    learning_patterns
  ].freeze

  # Layout sizes
  LAYOUTS = %w[small medium large full].freeze

  validates :widget_type, presence: true, inclusion: { in: WIDGET_TYPES }
  validates :title, presence: true
  validates :layout, inclusion: { in: LAYOUTS }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :width, numericality: { greater_than: 0, less_than_or_equal_to: 12 }
  validates :height, numericality: { greater_than: 0 }

  scope :visible, -> { where(visible: true) }
  scope :ordered, -> { order(:position) }
  scope :by_type, ->(type) { where(widget_type: type) }

  # Default configurations for each widget type
  DEFAULT_CONFIGS = {
    'progress' => {
      show_percentage: true,
      show_mastered: true,
      show_weak: true,
      show_untested: true
    },
    'recent_scores' => {
      limit: 10,
      chart_type: 'line',
      show_trend: true
    },
    'weakness_analysis' => {
      limit: 5,
      show_recommendations: true,
      group_by: 'concept'
    },
    'goal_achievement' => {
      show_progress_bar: true,
      show_percentage: true,
      show_remaining: true
    },
    'study_time' => {
      period: 'week',
      chart_type: 'bar',
      show_breakdown: true
    },
    'ranking' => {
      scope: 'global',
      limit: 10,
      show_position: true
    },
    'upcoming_exams' => {
      limit: 5,
      show_countdown: true,
      show_preparation_status: true
    },
    'recommendations' => {
      limit: 5,
      algorithm: 'hybrid',
      show_reasoning: true
    },
    'achievements' => {
      show_badges: true,
      show_milestones: true,
      show_progress: true
    },
    'learning_patterns' => {
      show_heatmap: true,
      show_preferred_times: true,
      show_session_stats: true
    }
  }.freeze

  before_create :set_default_configuration

  def config
    configuration || {}
  end

  def update_config(new_config)
    self.configuration = (config || {}).merge(new_config)
    save
  end

  def reset_to_default
    self.configuration = DEFAULT_CONFIGS[widget_type] || {}
    save
  end

  private

  def set_default_configuration
    self.configuration ||= DEFAULT_CONFIGS[widget_type] || {}
  end
end
