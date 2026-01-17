# API endpoint for Knowledge Graph data
class Api::V1::KnowledgeGraphsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:show, :nodes, :edges, :statistics, :weak_concepts, :learning_path]

  # GET /api/v1/knowledge_graphs/:study_material_id
  def show
    graph_data = build_graph_data

    render json: {
      success: true,
      graph: graph_data,
      metadata: graph_metadata
    }
  end

  # GET /api/v1/knowledge_graphs/:study_material_id/nodes
  def nodes
    nodes = @study_material.knowledge_nodes
                          .includes(:knowledge_edges, :user_masteries)
                          .order(importance: :desc)

    formatted_nodes = nodes.map do |node|
      user_mastery = node.user_masteries.find_by(user: current_user)

      {
        id: node.id,
        name: node.name,
        level: node.level,
        description: node.description,
        importance: node.importance,
        difficulty: node.difficulty,
        mastery_status: user_mastery&.mastery_status || 'untested',
        mastery_percentage: user_mastery&.mastery_percentage || 0,
        correct_count: user_mastery&.correct_count || 0,
        incorrect_count: user_mastery&.incorrect_count || 0,
        question_count: node.questions.count,
        position: calculate_node_position(node),
        color: determine_node_color(user_mastery),
        size: calculate_node_size(node)
      }
    end

    render json: {
      success: true,
      nodes: formatted_nodes,
      total_count: nodes.count
    }
  end

  # GET /api/v1/knowledge_graphs/:study_material_id/edges
  def edges
    edges = KnowledgeEdge.where(knowledge_node_id: @study_material.knowledge_nodes.pluck(:id))
                        .includes(:knowledge_node, :related_node)

    formatted_edges = edges.map do |edge|
      {
        id: edge.id,
        source_id: edge.knowledge_node_id,
        target_id: edge.related_node_id,
        type: edge.relationship_type,
        weight: edge.weight || 0.5,
        reasoning: edge.reasoning,
        prerequisite_strength: edge.prerequisite_strength
      }
    end

    render json: {
      success: true,
      edges: formatted_edges,
      total_count: edges.count
    }
  end

  # GET /api/v1/knowledge_graphs/:study_material_id/statistics
  def statistics
    nodes = @study_material.knowledge_nodes
    user_masteries = current_user.user_masteries.where(knowledge_node_id: nodes.pluck(:id))

    stats = {
      total_concepts: nodes.count,
      mastered_concepts: user_masteries.where(mastery_status: 'mastered').count,
      learning_concepts: user_masteries.where(mastery_status: 'learning').count,
      weak_concepts: user_masteries.where(mastery_status: 'weak').count,
      untested_concepts: nodes.count - user_masteries.count,
      average_mastery: user_masteries.average(:mastery_percentage)&.to_f&.round(2) || 0,
      concepts_by_level: nodes.group(:level).count,
      concepts_by_difficulty: nodes.group(:difficulty).count,
      questions_per_concept: (nodes.joins(:questions).count.to_f / nodes.count).round(2)
    }

    render json: {
      success: true,
      statistics: stats
    }
  end

  # GET /api/v1/knowledge_graphs/:study_material_id/weak_concepts
  def weak_concepts
    analyzer = AdvancedWeaknessAnalyzer.new(current_user, @study_material)
    analysis = analyzer.analyze

    weak_concepts = analysis[:severity_scores].select do |concept|
      concept[:severity_level].in?(['significant', 'critical'])
    end

    render json: {
      success: true,
      weak_concepts: weak_concepts,
      priority_ranking: analysis[:priority_ranking].take(10),
      recommendations: analyzer.send(:generate_priority_recommendations, analysis).take(5)
    }
  end

  # GET /api/v1/knowledge_graphs/:study_material_id/learning_path
  def learning_path
    weak_nodes = current_user.user_masteries
                            .where(knowledge_node_id: @study_material.knowledge_nodes.pluck(:id))
                            .where('mastery_percentage < ?', 60)
                            .order(mastery_percentage: :asc)
                            .limit(10)
                            .includes(:knowledge_node)

    learning_path = weak_nodes.map.with_index do |mastery, index|
      node = mastery.knowledge_node
      prerequisites = node.knowledge_edges
                         .where(relationship_type: 'prerequisite')
                         .includes(:related_node)

      {
        order: index + 1,
        concept_id: node.id,
        concept_name: node.name,
        current_mastery: mastery.mastery_percentage,
        difficulty: node.difficulty,
        importance: node.importance,
        estimated_study_hours: estimate_study_hours(mastery.mastery_percentage, node.difficulty),
        prerequisites: prerequisites.map do |edge|
          {
            id: edge.related_node_id,
            name: edge.related_node.name,
            strength: edge.prerequisite_strength || 50
          }
        end,
        suggested_questions: node.questions.limit(5).pluck(:id)
      }
    end

    render json: {
      success: true,
      learning_path: learning_path,
      total_concepts_to_study: learning_path.count,
      estimated_total_hours: learning_path.sum { |item| item[:estimated_study_hours] }
    }
  end

  # POST /api/v1/knowledge_graphs/:study_material_id/analyze_weakness
  def analyze_weakness
    analyzer = AdvancedWeaknessAnalyzer.new(current_user, @study_material)

    report = analyzer.generate_report(report_type: params[:report_type] || 'quick')

    render json: {
      success: true,
      report_id: report.id,
      summary: {
        total_weaknesses: report.statistics[:total_weaknesses],
        critical_count: report.statistics[:critical_count],
        overall_severity: report.statistics[:overall_severity],
        improvement_rate: report.statistics[:improvement_rate],
        percentile: report.statistics[:percentile]
      },
      redirect_url: weakness_report_path(report)
    }
  end

  private

  def set_study_material
    @study_material = current_user.study_sets
                                  .joins(:study_materials)
                                  .find_by('study_materials.id = ?', params[:study_material_id] || params[:id])
                                  &.study_materials
                                  &.find(params[:study_material_id] || params[:id])

    unless @study_material
      render json: { error: 'Study material not found' }, status: :not_found
    end
  end

  def build_graph_data
    {
      nodes: Api::V1::KnowledgeGraphsController.new.nodes.parsed_body[:nodes],
      edges: Api::V1::KnowledgeGraphsController.new.edges.parsed_body[:edges],
      layout: 'force-directed',
      viewport: {
        center: [0, 0, 0],
        zoom: 1.0
      }
    }
  end

  def graph_metadata
    {
      study_material_id: @study_material.id,
      study_material_name: @study_material.name,
      total_nodes: @study_material.knowledge_nodes.count,
      total_edges: KnowledgeEdge.where(knowledge_node_id: @study_material.knowledge_nodes.pluck(:id)).count,
      user_progress: calculate_user_progress,
      last_updated: @study_material.updated_at
    }
  end

  def calculate_node_position(node)
    # Simple layout algorithm - in production, use force-directed layout
    level_y = case node.level
              when 'subject' then 100
              when 'chapter' then 200
              when 'concept' then 300
              else 400
              end

    {
      x: rand(-500..500),
      y: level_y,
      z: rand(-200..200)
    }
  end

  def determine_node_color(user_mastery)
    return '#9CA3AF' unless user_mastery # Gray for untested

    case user_mastery.mastery_status
    when 'mastered'
      '#10B981' # Green
    when 'learning'
      '#F59E0B' # Orange
    when 'weak'
      '#EF4444' # Red
    else
      '#9CA3AF' # Gray
    end
  end

  def calculate_node_size(node)
    # Size based on importance and question count
    base_size = 10
    importance_factor = (node.importance || 5) / 10.0
    question_factor = Math.log([node.questions.count, 1].max, 2) / 5.0

    (base_size * (1 + importance_factor + question_factor)).round(2)
  end

  def calculate_user_progress
    total_nodes = @study_material.knowledge_nodes.count
    return 0 if total_nodes.zero?

    mastered = current_user.user_masteries
                          .where(knowledge_node_id: @study_material.knowledge_nodes.pluck(:id))
                          .where(mastery_status: 'mastered')
                          .count

    ((mastered.to_f / total_nodes) * 100).round(2)
  end

  def estimate_study_hours(current_mastery, difficulty)
    gap = 80 - current_mastery
    difficulty_multiplier = difficulty / 3.0

    hours = (gap / 10.0) * difficulty_multiplier
    [hours.round(1), 0.5].max
  end
end
