# Knowledge Graph Controller
# 지식 그래프 생성, 조회, 분석 API

class KnowledgeGraphController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material

  # POST /api/knowledge_graph/:study_material_id/build
  # 지식 그래프 구축
  def build
    begin
      # 백그라운드로 그래프 구축 작업 시작
      UpdateKnowledgeGraphJob.perform_later(@study_material.id)

      render json: {
        success: true,
        message: 'Knowledge graph building started',
        study_material_id: @study_material.id
      }
    rescue StandardError => e
      render json: {
        success: false,
        message: "Failed to start knowledge graph building: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  # GET /api/knowledge_graph/:study_material_id
  # 지식 그래프 조회
  def show
    graph_service = KnowledgeGraphService.new(@study_material)
    graph_data = graph_service.export_graph_as_json(current_user)

    render json: {
      success: true,
      graph: graph_data
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to retrieve knowledge graph: #{e.message}"
    }, status: :internal_server_error
  end

  # GET /api/knowledge_graph/:study_material_id/stats
  # 지식 그래프 통계
  def stats
    graph_service = KnowledgeGraphService.new(@study_material)
    statistics = graph_service.graph_statistics

    render json: {
      success: true,
      stats: statistics
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to retrieve statistics: #{e.message}"
    }, status: :internal_server_error
  end

  # GET /api/knowledge_graph/:study_material_id/nodes
  # 특정 조건의 노드 조회
  def nodes
    nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)

    # 필터링
    nodes = nodes.by_level(params[:level]) if params[:level].present?
    nodes = nodes.by_difficulty(params[:difficulty]) if params[:difficulty].present?
    nodes = nodes.by_parent(params[:parent_name]) if params[:parent_name].present?

    render json: {
      success: true,
      nodes: nodes.map { |n| n.to_graph_json(current_user) },
      total: nodes.count
    }
  end

  # GET /api/knowledge_graph/:study_material_id/nodes/:node_id
  # 특정 노드 상세 조회
  def node_detail
    node = KnowledgeNode.find(params[:node_id])

    if node.study_material_id != @study_material.id
      return render json: {
        success: false,
        message: 'Node does not belong to this study material'
      }, status: :forbidden
    end

    render json: {
      success: true,
      node: node.to_detailed_json(current_user),
      prerequisites: node.prerequisites.map { |n| n.to_graph_json(current_user) },
      dependents: node.dependents.map { |n| n.to_graph_json(current_user) },
      children: node.children.map { |n| n.to_graph_json(current_user) }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Node not found'
    }, status: :not_found
  end

  # GET /api/knowledge_graph/:study_material_id/learning_path
  # 두 노드 간 학습 경로 찾기
  def learning_path
    from_node = KnowledgeNode.find(params[:from_node_id])
    to_node = KnowledgeNode.find(params[:to_node_id])

    graph_service = KnowledgeGraphService.new(@study_material)
    path = graph_service.find_learning_path(from_node, to_node)

    if path
      render json: {
        success: true,
        path: path.map { |n| n.to_graph_json(current_user) },
        path_length: path.length
      }
    else
      render json: {
        success: false,
        message: 'No path found between the nodes'
      }
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: {
      success: false,
      message: "Node not found: #{e.message}"
    }, status: :not_found
  end

  # POST /api/knowledge_graph/:study_material_id/extract_from_question
  # 특정 문제에서 개념 추출 및 그래프 업데이트
  def extract_from_question
    question = Question.find(params[:question_id])

    if question.study_material_id != @study_material.id
      return render json: {
        success: false,
        message: 'Question does not belong to this study material'
      }, status: :forbidden
    end

    graph_service = KnowledgeGraphService.new(@study_material)
    concept_nodes = graph_service.extract_and_build_graph_from_question(question)

    render json: {
      success: true,
      message: 'Concepts extracted and graph updated',
      concepts: concept_nodes.map { |n| n.to_graph_json(current_user) }
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Question not found'
    }, status: :not_found
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to extract concepts: #{e.message}"
    }, status: :internal_server_error
  end

  # GET /api/knowledge_graph/:study_material_id/weak_concepts
  # 사용자의 약한 개념 찾기
  def weak_concepts
    nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)
    user_masteries = current_user.user_masteries.where(knowledge_node: nodes)

    weak_nodes = user_masteries.where('mastery_level < ?', 0.6)
                               .order(mastery_level: :asc)
                               .limit(params[:limit] || 10)
                               .includes(:knowledge_node)

    render json: {
      success: true,
      weak_concepts: weak_nodes.map do |mastery|
        node = mastery.knowledge_node
        {
          **node.to_graph_json(current_user),
          mastery_level: mastery.mastery_level,
          attempts: mastery.attempts,
          correct_attempts: mastery.correct_attempts,
          accuracy: mastery.attempts > 0 ? (mastery.correct_attempts.to_f / mastery.attempts).round(3) : 0
        }
      end
    }
  end

  # GET /api/knowledge_graph/:study_material_id/mastered_concepts
  # 사용자가 숙달한 개념 찾기
  def mastered_concepts
    nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)
    user_masteries = current_user.user_masteries.where(knowledge_node: nodes)

    mastered_nodes = user_masteries.where('mastery_level >= ?', 0.8)
                                   .order(mastery_level: :desc)
                                   .limit(params[:limit] || 10)
                                   .includes(:knowledge_node)

    render json: {
      success: true,
      mastered_concepts: mastered_nodes.map do |mastery|
        node = mastery.knowledge_node
        {
          **node.to_graph_json(current_user),
          mastery_level: mastery.mastery_level,
          attempts: mastery.attempts,
          correct_attempts: mastery.correct_attempts
        }
      end
    }
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Study material not found'
    }, status: :not_found
  end
end
