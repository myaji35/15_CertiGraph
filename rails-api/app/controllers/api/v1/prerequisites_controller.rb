class Api::V1::PrerequisitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [
    :analyze_all, :graph_data, :validate_graph, :fix_cycles,
    :generate_paths, :create_path, :update_path_progress
  ]
  before_action :set_knowledge_node, only: [
    :analyze_node, :node_prerequisites, :node_dependents,
    :calculate_depth, :generate_paths
  ]
  before_action :set_learning_path, only: [
    :show_path, :update_path_progress, :abandon_path, :path_alternatives
  ]

  # GET /api/study_materials/:study_material_id/prerequisites/analyze_all
  # Analyze all nodes and create prerequisite relationships
  def analyze_all
    service = PrerequisiteAnalysisService.new(@study_material)

    # Run analysis in background if large dataset
    if @study_material.knowledge_nodes.count > 50
      job = AnalyzePrerequisitesJob.perform_later(@study_material.id)
      render json: {
        message: "Analysis queued for background processing",
        job_id: job.job_id,
        node_count: @study_material.knowledge_nodes.count
      }, status: :accepted
    else
      results = service.analyze_all_prerequisites
      render json: {
        message: "Prerequisites analysis completed",
        results: results
      }
    end
  end

  # GET /api/study_materials/:study_material_id/prerequisites/nodes/:node_id/analyze
  # Analyze prerequisites for a specific node
  def analyze_node
    service = PrerequisiteAnalysisService.new(@study_material)
    prerequisites = service.analyze_node_prerequisites(@knowledge_node)

    render json: {
      node: {
        id: @knowledge_node.id,
        name: @knowledge_node.name,
        level: @knowledge_node.level
      },
      prerequisites: prerequisites.map do |prereq|
        {
          node_id: prereq[:node].id,
          node_name: prereq[:node].name,
          weight: prereq[:weight],
          strength: prereq[:strength],
          reasoning: prereq[:reasoning],
          confidence: prereq[:confidence]
        }
      end,
      total_found: prerequisites.size
    }
  end

  # GET /api/study_materials/:study_material_id/prerequisites/graph_data
  # Get prerequisite graph visualization data
  def graph_data
    service = PrerequisiteAnalysisService.new(@study_material)
    data = service.generate_graph_data

    render json: {
      graph: data,
      visualization_ready: true
    }
  end

  # GET /api/study_materials/:study_material_id/prerequisites/nodes/:node_id/prerequisites
  # Get all prerequisites for a node
  def node_prerequisites
    direct = @knowledge_node.prerequisites
    all_prereqs = @knowledge_node.all_prerequisites

    render json: {
      node: {
        id: @knowledge_node.id,
        name: @knowledge_node.name
      },
      direct_prerequisites: direct.map { |n| node_summary(n) },
      all_prerequisites: all_prereqs.map { |n| node_summary(n) },
      direct_count: direct.count,
      total_count: all_prereqs.count
    }
  end

  # GET /api/study_materials/:study_material_id/prerequisites/nodes/:node_id/dependents
  # Get all nodes that depend on this node
  def node_dependents
    direct = @knowledge_node.dependents
    all_deps = @knowledge_node.all_dependents

    render json: {
      node: {
        id: @knowledge_node.id,
        name: @knowledge_node.name
      },
      direct_dependents: direct.map { |n| node_summary(n) },
      all_dependents: all_deps.map { |n| node_summary(n) },
      direct_count: direct.count,
      total_count: all_deps.count
    }
  end

  # GET /api/study_materials/:study_material_id/prerequisites/nodes/:node_id/depth
  # Calculate dependency depth for a node
  def calculate_depth
    service = PrerequisiteAnalysisService.new(@study_material)
    depth = service.calculate_depth(@knowledge_node)

    render json: {
      node: {
        id: @knowledge_node.id,
        name: @knowledge_node.name
      },
      depth: depth,
      interpretation: depth_interpretation(depth)
    }
  end

  # GET /api/study_materials/:study_material_id/prerequisites/validate
  # Validate the entire prerequisite graph
  def validate_graph
    validator = DependencyValidator.new
    validation = validator.validate_graph(@study_material)

    render json: {
      validation: validation,
      health_score: validator.calculate_health_score(@study_material)
    }
  end

  # POST /api/study_materials/:study_material_id/prerequisites/fix_cycles
  # Automatically fix circular dependencies
  def fix_cycles
    validator = DependencyValidator.new
    fixed = validator.fix_circular_dependencies(@study_material)

    render json: {
      message: "Circular dependencies fixed",
      fixed_count: fixed.size,
      fixed_edges: fixed
    }
  end

  # POST /api/study_materials/:study_material_id/prerequisites/generate_paths
  # Generate multiple learning path options to a target node
  def generate_paths
    service = LearningPathService.new(current_user, @study_material)
    paths = service.generate_paths(@knowledge_node)

    render json: {
      target_node: {
        id: @knowledge_node.id,
        name: @knowledge_node.name
      },
      paths: paths.map { |p| path_summary(p) },
      total_options: paths.size
    }
  end

  # POST /api/study_materials/:study_material_id/prerequisites/paths
  # Create and save a learning path
  def create_path
    path_data = params.require(:path).permit(
      :target_node_id, :path_type, :path_name, :description,
      :mastery_requirement, :priority
    )

    target_node = @study_material.knowledge_nodes.find(path_data[:target_node_id])
    service = LearningPathService.new(current_user, @study_material)

    # Generate the requested path type
    path_option = case path_data[:path_type]
    when 'shortest'
      service.generate_shortest_path(target_node)
    when 'comprehensive'
      service.generate_comprehensive_path(target_node)
    when 'beginner_friendly'
      service.generate_beginner_friendly_path(target_node)
    when 'adaptive'
      service.generate_adaptive_path(target_node)
    else
      service.generate_shortest_path(target_node)
    end

    if path_option.nil?
      render json: { error: "Could not generate path" }, status: :unprocessable_entity
      return
    end

    # Create the learning path
    path = LearningPath.create!(
      user: current_user,
      study_material: @study_material,
      target_node: target_node,
      path_name: path_data[:path_name] || path_option[:path_name],
      path_type: path_data[:path_type],
      description: path_data[:description] || path_option[:description],
      node_sequence: path_option[:node_sequence],
      edge_sequence: path_option[:edge_sequence],
      total_nodes: path_option[:total_nodes],
      difficulty_level: path_option[:difficulty_level],
      estimated_hours: path_option[:estimated_hours],
      mastery_requirement: path_data[:mastery_requirement] || 0.8,
      priority: path_data[:priority] || path_option[:priority],
      status: 'active',
      started_at: Time.current
    )

    render json: {
      message: "Learning path created",
      path: path.to_detailed_json
    }, status: :created
  end

  # GET /api/learning_paths/:id
  # Get learning path details
  def show_path
    render json: {
      path: @learning_path.to_detailed_json,
      visualization: @learning_path.to_visualization_json
    }
  end

  # PATCH /api/learning_paths/:id/progress
  # Update progress on a learning path
  def update_path_progress
    node_id = params.require(:node_id)

    service = LearningPathService.new(current_user, @study_material)
    updated_path = service.update_path_progress(@learning_path, node_id)

    if updated_path.completed?
      suggestions = service.suggest_next_goals(updated_path)

      render json: {
        message: "Path completed! Congratulations!",
        path: updated_path.to_detailed_json,
        next_goals: suggestions
      }
    else
      render json: {
        message: "Progress updated",
        path: updated_path.to_detailed_json,
        next_node: updated_path.next_node
      }
    end
  end

  # POST /api/learning_paths/:id/abandon
  # Abandon a learning path
  def abandon_path
    @learning_path.update!(
      status: 'abandoned',
      abandonment_count: @learning_path.abandonment_count + 1
    )

    render json: {
      message: "Learning path abandoned",
      path_id: @learning_path.id
    }
  end

  # GET /api/learning_paths/:id/alternatives
  # Get alternative learning paths
  def path_alternatives
    service = LearningPathService.new(current_user, @study_material)
    alternatives = service.get_alternative_paths(@learning_path)

    render json: {
      current_path: path_summary(@learning_path),
      alternatives: alternatives.map { |p| path_summary(p) },
      total_alternatives: alternatives.size
    }
  end

  # GET /api/users/learning_paths
  # Get all learning paths for current user
  def user_paths
    paths = current_user.learning_paths
      .includes(:study_material, :target_node)
      .order(last_activity_at: :desc, created_at: :desc)

    active_paths = paths.where(status: 'active')
    completed_paths = paths.where(status: 'completed')

    render json: {
      active_paths: active_paths.map { |p| path_summary(p) },
      completed_paths: completed_paths.map { |p| path_summary(p) },
      statistics: {
        total_paths: paths.count,
        active_count: active_paths.count,
        completed_count: completed_paths.count,
        total_nodes_completed: active_paths.sum(:completed_nodes),
        avg_completion_rate: active_paths.average(:completion_percentage)&.round(2) || 0
      }
    }
  end

  # POST /api/study_materials/:study_material_id/prerequisites/batch_analyze
  # Batch analyze multiple nodes
  def batch_analyze
    node_ids = params.require(:node_ids)

    service = PrerequisiteAnalysisService.new(@study_material)
    results = service.batch_analyze(node_ids)

    render json: {
      message: "Batch analysis completed",
      results: results,
      analyzed_count: results.size
    }
  end

  # DELETE /api/v1/prerequisites/:id
  # Delete a prerequisite edge
  def destroy
    edge = KnowledgeEdge.find(params[:id])

    # Authorize: ensure user has access to the study material
    unless edge.from_node.study_material.user_id == current_user.id || current_user.admin?
      return render json: { error: 'Unauthorized' }, status: :forbidden
    end

    from_node = edge.from_node
    to_node = edge.to_node

    edge.destroy

    render json: {
      message: "Prerequisite relationship deleted",
      from_node: { id: from_node.id, name: from_node.name },
      to_node: { id: to_node.id, name: to_node.name }
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Prerequisite edge not found' }, status: :not_found
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Study material not found" }, status: :not_found
  end

  def set_knowledge_node
    @knowledge_node = @study_material.knowledge_nodes.find(params[:node_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Knowledge node not found" }, status: :not_found
  end

  def set_learning_path
    @learning_path = current_user.learning_paths.find(params[:id])
    @study_material = @learning_path.study_material
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Learning path not found" }, status: :not_found
  end

  def node_summary(node)
    {
      id: node.id,
      name: node.name,
      level: node.level,
      difficulty: node.difficulty,
      importance: node.importance,
      description: node.description
    }
  end

  def path_summary(path)
    # Handle both LearningPath models and hash objects
    if path.is_a?(Hash)
      {
        path_type: path[:path_type],
        path_name: path[:path_name],
        description: path[:description],
        total_nodes: path[:total_nodes],
        difficulty_level: path[:difficulty_level],
        estimated_hours: path[:estimated_hours],
        priority: path[:priority]
      }
    else
      {
        id: path.id,
        path_name: path.path_name,
        path_type: path.path_type,
        status: path.status,
        total_nodes: path.total_nodes,
        completed_nodes: path.completed_nodes,
        completion_percentage: path.completion_percentage,
        difficulty_level: path.difficulty_level,
        estimated_hours: path.estimated_hours,
        actual_hours: path.actual_hours,
        path_score: path.path_score,
        priority: path.priority,
        started_at: path.started_at,
        last_activity_at: path.last_activity_at
      }
    end
  end

  def depth_interpretation(depth)
    case depth
    when 0
      "Foundation concept - no prerequisites"
    when 1..2
      "Basic concept - few prerequisites"
    when 3..4
      "Intermediate concept - moderate prerequisites"
    when 5..7
      "Advanced concept - many prerequisites"
    else
      "Expert concept - extensive prerequisite chain"
    end
  end

  def authenticate_user!
    # Implement your authentication logic
    # For now, we'll assume @current_user is set
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_user
    @current_user
  end
end
