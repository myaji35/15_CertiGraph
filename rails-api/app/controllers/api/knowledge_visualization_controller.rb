class Api::KnowledgeVisualizationController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:graph_data, :node_detail, :statistics, :filter_nodes]

  # GET /api/knowledge_visualization/:id/graph_data
  # Returns 3D graph data with nodes and edges
  def graph_data
    service = ThreeDGraphService.new(@study_material, current_user)
    graph_data = service.generate_3d_graph

    render json: {
      success: true,
      data: graph_data,
      message: "3D graph data generated successfully"
    }
  rescue StandardError => e
    Rails.logger.error("3D graph generation failed: #{e.message}")
    render json: {
      success: false,
      error: e.message,
      message: "Failed to generate 3D graph data"
    }, status: :internal_server_error
  end

  # GET /api/knowledge_visualization/:id/nodes/:node_id
  # Returns detailed information about a specific node
  def node_detail
    node = KnowledgeNode.find(params[:node_id])

    unless node.study_material_id == @study_material.id
      return render json: {
        success: false,
        message: "Node does not belong to this study material"
      }, status: :forbidden
    end

    mastery = UserMastery.find_by(user: current_user, knowledge_node: node)

    render json: {
      success: true,
      data: {
        node: node.to_detailed_json(current_user),
        mastery: mastery&.to_json,
        prerequisites: node.prerequisites.map(&:name),
        dependents: node.dependents.map(&:name),
        related_questions: node.test_questions.count rescue 0,
        learning_path: generate_learning_path(node)
      }
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      success: false,
      message: "Node not found"
    }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("Node detail fetch failed: #{e.message}")
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  # GET /api/knowledge_visualization/:id/statistics
  def statistics
    nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)
    masteries = UserMastery.joins(:knowledge_node)
                          .where(user: current_user, knowledge_nodes: { study_material_id: @study_material.id })

    total_nodes = nodes.count
    mastered_count = masteries.where(color: 'green').count
    weak_count = masteries.where(color: 'red').count
    learning_count = masteries.where(color: 'yellow').count
    untested_count = total_nodes - (mastered_count + weak_count + learning_count)

    render json: {
      success: true,
      data: {
        total_nodes: total_nodes,
        mastered: mastered_count,
        weak: weak_count,
        learning: learning_count,
        untested: untested_count,
        mastered_percentage: total_nodes > 0 ? (mastered_count.to_f / total_nodes * 100).round(2) : 0,
        weak_percentage: total_nodes > 0 ? (weak_count.to_f / total_nodes * 100).round(2) : 0,
        overall_progress: total_nodes > 0 ? ((mastered_count + learning_count).to_f / total_nodes * 100).round(2) : 0
      }
    }
  rescue StandardError => e
    Rails.logger.error("Statistics calculation failed: #{e.message}")
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  # POST /api/knowledge_visualization/:id/filter
  # Filter nodes by criteria (difficulty, level, status)
  def filter_nodes
    nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)

    # Apply filters
    if params[:difficulty].present?
      nodes = nodes.where(difficulty: params[:difficulty])
    end

    if params[:level].present?
      nodes = nodes.where(level: params[:level])
    end

    if params[:status].present?
      mastery_ids = UserMastery.where(user: current_user, status: params[:status])
                              .pluck(:knowledge_node_id)
      nodes = nodes.where(id: mastery_ids)
    end

    if params[:color].present?
      mastery_ids = UserMastery.where(user: current_user, color: params[:color])
                              .pluck(:knowledge_node_id)
      nodes = nodes.where(id: mastery_ids)
    end

    service = ThreeDGraphService.new(@study_material, current_user)
    filtered_graph = service.generate_3d_graph(nodes: nodes)

    render json: {
      success: true,
      data: filtered_graph,
      filters_applied: params.slice(:difficulty, :level, :status, :color)
    }
  rescue StandardError => e
    Rails.logger.error("Node filtering failed: #{e.message}")
    render json: {
      success: false,
      error: e.message
    }, status: :internal_server_error
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:id] || params[:study_material_id])

    unless @study_material.user_id == current_user.id
      render json: {
        success: false,
        message: "You don't have access to this study material"
      }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Study material not found"
    }, status: :not_found
  end

  def generate_learning_path(target_node)
    # Find weak prerequisite nodes
    weak_prereqs = target_node.all_prerequisites.select do |node|
      mastery = UserMastery.find_by(user: current_user, knowledge_node: node)
      mastery && mastery.color == 'red'
    end

    # Sort by importance and dependency depth
    weak_prereqs.sort_by { |node| [-node.importance, node.name] }
               .first(5)
               .map { |node| { id: node.id, name: node.name, importance: node.importance } }
  end
end
