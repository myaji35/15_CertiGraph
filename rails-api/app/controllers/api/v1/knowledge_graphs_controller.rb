module Api
  module V1
    class KnowledgeGraphsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_study_material, only: [:show, :nodes, :edges, :statistics, :analysis]

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph
      def show
        service = KnowledgeGraphService.new(@study_material)
        graph_data = service.export_graph_as_json(current_user)

        render json: {
          success: true,
          data: graph_data
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/nodes
      def nodes
        nodes = KnowledgeNode.where(study_material_id: @study_material.id, active: true)
                            .page(params[:page])
                            .per(params[:per_page] || 20)

        render json: {
          success: true,
          data: nodes.map { |n| n.to_detailed_json(current_user) },
          pagination: {
            current_page: nodes.current_page,
            total_pages: nodes.total_pages,
            total_count: nodes.total_count
          }
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/edges
      def edges
        edges = KnowledgeEdge.joins(:knowledge_node)
                            .where(
                              knowledge_nodes: { study_material_id: @study_material.id },
                              active: true
                            )
                            .page(params[:page])
                            .per(params[:per_page] || 50)

        render json: {
          success: true,
          data: edges.map(&:to_json),
          pagination: {
            current_page: edges.current_page,
            total_pages: edges.total_pages,
            total_count: edges.total_count
          }
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/statistics
      def statistics
        service = KnowledgeGraphService.new(@study_material)
        stats = service.graph_statistics

        render json: {
          success: true,
          data: stats
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/analysis
      def analysis
        analysis_service = GraphAnalysisService.new(current_user, @study_material)

        render json: {
          success: true,
          data: {
            weak_areas: analysis_service.identify_weak_areas,
            strong_areas: analysis_service.identify_strong_areas,
            recommended_path: analysis_service.recommend_learning_path(limit: 10),
            progress_percentage: analysis_service.calculate_progress_percentage,
            overall_difficulty: analysis_service.calculate_overall_difficulty,
            dashboard_summary: analysis_service.dashboard_summary
          }
        }
      end

      # POST /api/v1/study_materials/:study_material_id/knowledge_graph/build
      def build
        service = KnowledgeGraphService.new(@study_material)

        # 모든 질문에 대해 그래프 구축
        questions = @study_material.questions
        concepts_created = 0

        questions.each do |question|
          concepts = service.extract_and_build_graph_from_question(question)
          concepts_created += concepts.length
        end

        # 온톨로지 계층 구조 구축
        service.build_ontology_hierarchy

        render json: {
          success: true,
          message: "Knowledge graph built successfully",
          data: {
            concepts_created: concepts_created,
            questions_processed: questions.count
          }
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/concept_map
      def concept_map
        analysis_service = GraphAnalysisService.new(current_user, @study_material)
        concept_map = analysis_service.generate_concept_map

        render json: {
          success: true,
          data: concept_map
        }
      end

      # GET /api/v1/study_materials/:study_material_id/knowledge_graph/learning_strategy
      def learning_strategy
        analysis_service = GraphAnalysisService.new(current_user, @study_material)
        strategy = analysis_service.suggest_learning_strategy

        if strategy
          render json: {
            success: true,
            data: strategy
          }
        else
          render json: {
            success: false,
            message: "No learning strategy available"
          }, status: :not_found
        end
      end

      # GET /api/v1/knowledge_nodes/:id
      def show_node
        node = KnowledgeNode.find(params[:id])
        authorize_node_access(node)

        render json: {
          success: true,
          data: node.to_detailed_json(current_user)
        }
      end

      # GET /api/v1/knowledge_nodes/:id/prerequisites
      def node_prerequisites
        node = KnowledgeNode.find(params[:id])
        authorize_node_access(node)

        prerequisites = node.all_prerequisites

        render json: {
          success: true,
          data: prerequisites.map { |p| p.to_detailed_json(current_user) }
        }
      end

      # GET /api/v1/knowledge_nodes/:id/dependents
      def node_dependents
        node = KnowledgeNode.find(params[:id])
        authorize_node_access(node)

        dependents = node.all_dependents

        render json: {
          success: true,
          data: dependents.map { |d| d.to_detailed_json(current_user) }
        }
      end

      private

      def set_study_material
        @study_material = StudyMaterial.find(params[:study_material_id])
        authorize_material_access
      end

      def authorize_material_access
        unless current_user.study_sets.find_by(id: @study_material.study_set_id)
          render json: { success: false, message: 'Unauthorized' }, status: :forbidden
        end
      end

      def authorize_node_access(node)
        unless current_user.study_sets.find_by(id: node.study_material.study_set_id)
          render json: { success: false, message: 'Unauthorized' }, status: :forbidden
        end
      end
    end
  end
end
