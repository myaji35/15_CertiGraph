class LearningPath < ApplicationRecord
  belongs_to :user
  belongs_to :study_material
  belongs_to :target_node, class_name: 'KnowledgeNode', optional: true

  validates :path_name, presence: true
  validates :path_type, inclusion: { in: %w(shortest comprehensive beginner_friendly adaptive custom) }
  validates :status, inclusion: { in: %w(active completed abandoned paused) }
  validates :difficulty_level, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :mastery_requirement, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 1.0 }
  validates :priority, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  scope :by_priority, -> { order(priority: :desc) }
  scope :by_completion, -> { order(completion_percentage: :desc) }
  scope :recent, -> { order(last_activity_at: :desc) }

  # Path type helpers
  def shortest?
    path_type == 'shortest'
  end

  def comprehensive?
    path_type == 'comprehensive'
  end

  def beginner_friendly?
    path_type == 'beginner_friendly'
  end

  # Status helpers
  def active?
    status == 'active'
  end

  def completed?
    status == 'completed'
  end

  def abandoned?
    status == 'abandoned'
  end

  # Progress management
  def update_progress!
    return unless node_sequence.present?

    self.total_nodes = node_sequence.size
    self.completed_nodes = count_completed_nodes
    self.completion_percentage = calculate_completion_percentage

    # Update status if completed
    if completion_percentage >= 100.0 && status != 'completed'
      self.status = 'completed'
      self.completed_at = Time.current
    end

    save
  end

  def mark_node_completed(node_id)
    mastery_checkpoints[node_id.to_s] = {
      'completed_at' => Time.current.iso8601,
      'mastery_level' => get_current_mastery(node_id)
    }
    update_progress!
  end

  def next_node
    return nil if completed?

    node_sequence.find do |node_id|
      !node_completed?(node_id)
    end
  end

  def node_completed?(node_id)
    checkpoint = mastery_checkpoints[node_id.to_s]
    return false unless checkpoint

    mastery_level = checkpoint['mastery_level'] || 0.0
    mastery_level >= mastery_requirement
  end

  # Analytics
  def time_per_node
    return 0 if completed_nodes.zero?
    actual_hours.to_f / completed_nodes
  end

  def estimated_time_remaining
    return 0 if completed?
    remaining_nodes = total_nodes - completed_nodes
    (time_per_node * remaining_nodes).ceil
  end

  def on_track?
    return true unless estimated_completion_at

    expected_completion = Time.current + estimated_time_remaining.hours
    expected_completion <= estimated_completion_at
  end

  # Path quality
  def calculate_path_score
    factors = []

    # Factor 1: Completion rate
    factors << completion_percentage / 100.0

    # Factor 2: Average mastery level
    avg_mastery = average_mastery_level
    factors << avg_mastery if avg_mastery > 0

    # Factor 3: Time efficiency (if we have data)
    if estimated_hours > 0 && actual_hours > 0
      time_efficiency = [1.0, estimated_hours.to_f / actual_hours].min
      factors << time_efficiency
    end

    # Factor 4: User satisfaction
    factors << user_satisfaction if user_satisfaction > 0

    return 0.0 if factors.empty?
    factors.sum / factors.size
  end

  def average_mastery_level
    return 0.0 if mastery_checkpoints.empty?

    levels = mastery_checkpoints.values.map { |cp| cp['mastery_level'] || 0.0 }
    levels.sum / levels.size
  end

  # Visualization data
  def to_visualization_json
    {
      id: id,
      path_name: path_name,
      path_type: path_type,
      status: status,
      nodes: node_sequence.map.with_index do |node_id, index|
        node = KnowledgeNode.find_by(id: node_id)
        next unless node

        {
          id: node_id,
          name: node.name,
          position: index,
          completed: node_completed?(node_id),
          mastery: mastery_checkpoints.dig(node_id.to_s, 'mastery_level') || 0.0,
          is_current: node_id == next_node
        }
      end.compact,
      edges: edge_sequence.map do |edge_id|
        edge = KnowledgeEdge.find_by(id: edge_id)
        next unless edge

        {
          id: edge_id,
          from: edge.knowledge_node_id,
          to: edge.related_node_id,
          type: edge.relationship_type,
          weight: edge.weight
        }
      end.compact,
      progress: {
        total_nodes: total_nodes,
        completed_nodes: completed_nodes,
        completion_percentage: completion_percentage,
        current_node: next_node
      },
      metrics: {
        difficulty_level: difficulty_level,
        estimated_hours: estimated_hours,
        actual_hours: actual_hours,
        path_score: path_score,
        time_per_node: time_per_node,
        estimated_time_remaining: estimated_time_remaining,
        on_track: on_track?
      }
    }
  end

  # Detailed JSON for API
  def to_detailed_json
    {
      id: id,
      user_id: user_id,
      study_material_id: study_material_id,
      target_node_id: target_node_id,
      path_name: path_name,
      path_type: path_type,
      status: status,
      description: description,
      success_criteria: success_criteria,
      node_sequence: node_sequence,
      edge_sequence: edge_sequence,
      total_nodes: total_nodes,
      completed_nodes: completed_nodes,
      completion_percentage: completion_percentage,
      difficulty_level: difficulty_level,
      estimated_hours: estimated_hours,
      actual_hours: actual_hours,
      path_score: path_score,
      mastery_requirement: mastery_requirement,
      priority: priority,
      started_at: started_at,
      last_activity_at: last_activity_at,
      completed_at: completed_at,
      estimated_completion_at: estimated_completion_at,
      mastery_checkpoints: mastery_checkpoints,
      learning_statistics: learning_statistics,
      alternative_paths: alternative_paths,
      metadata: metadata,
      analytics: {
        time_per_node: time_per_node,
        estimated_time_remaining: estimated_time_remaining,
        on_track: on_track?,
        average_mastery: average_mastery_level
      },
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def count_completed_nodes
    node_sequence.count { |node_id| node_completed?(node_id) }
  end

  def calculate_completion_percentage
    return 0.0 if total_nodes.zero?
    (completed_nodes.to_f / total_nodes * 100).round(2)
  end

  def get_current_mastery(node_id)
    mastery = UserMastery.find_by(user_id: user_id, knowledge_node_id: node_id)
    mastery&.mastery_level || 0.0
  end
end
