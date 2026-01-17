module Api
  module V1
    class ConceptsController < ApplicationController
      before_action :set_study_material, only: [
        :index, :create, :extract_all, :normalize_all, :cluster,
        :hierarchy, :gaps, :statistics
      ]
      before_action :set_concept, only: [:show, :update, :destroy, :synonyms, :related, :questions]

      # GET /api/v1/study_materials/:study_material_id/concepts
      def index
        concepts = @study_material.knowledge_nodes.active

        # Filtering
        concepts = concepts.by_level(params[:level]) if params[:level].present?
        concepts = concepts.by_difficulty(params[:difficulty]) if params[:difficulty].present?
        concepts = concepts.by_category(params[:category]) if params[:category].present?
        concepts = concepts.primary_concepts if params[:primary_only] == 'true'
        concepts = concepts.frequently_tested if params[:frequently_tested] == 'true'

        # Sorting
        concepts = apply_sorting(concepts)

        # Pagination
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 20, 100].min

        paginated = concepts.offset((page - 1) * per_page).limit(per_page)

        render json: {
          concepts: paginated.map { |c| c.to_graph_json(current_user) },
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: concepts.count,
            total_pages: (concepts.count.to_f / per_page).ceil
          }
        }
      end

      # GET /api/v1/concepts/:id
      def show
        render json: {
          concept: @concept.to_detailed_json(current_user),
          synonyms: @concept.concept_synonyms.active.map(&:to_json_api),
          questions: @concept.questions.limit(10).map { |q| { id: q.id, content: q.content[0..100] } },
          prerequisites: @concept.prerequisites.map(&:to_graph_json),
          dependents: @concept.dependents.map(&:to_graph_json)
        }
      end

      # POST /api/v1/study_materials/:study_material_id/concepts
      def create
        concept = @study_material.knowledge_nodes.build(concept_params)

        if concept.save
          render json: { concept: concept.to_graph_json }, status: :created
        else
          render json: { errors: concept.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/concepts/:id
      def update
        if @concept.update(concept_params)
          render json: { concept: @concept.to_detailed_json }
        else
          render json: { errors: @concept.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/concepts/:id
      def destroy
        @concept.update(active: false)
        render json: { message: 'Concept deactivated successfully' }
      end

      # POST /api/v1/study_materials/:study_material_id/concepts/extract_all
      def extract_all
        service = ConceptExtractionService.new(@study_material)

        result = service.extract_from_all_questions

        render json: {
          message: 'Concept extraction completed',
          result: result
        }
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # POST /api/v1/study_materials/:study_material_id/concepts/normalize_all
      def normalize_all
        service = ConceptNormalizationService.new(@study_material)

        result = service.normalize_all_concepts

        render json: {
          message: 'Concept normalization completed',
          result: result
        }
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # GET /api/v1/study_materials/:study_material_id/concepts/cluster
      def cluster
        service = ConceptClusteringService.new(@study_material)

        cluster_type = params[:type] || 'similarity'
        threshold = params[:threshold]&.to_f || 0.7

        clusters = case cluster_type
                   when 'similarity'
                     service.cluster_by_similarity(threshold: threshold)
                   when 'category'
                     service.cluster_by_category
                   when 'difficulty'
                     service.cluster_by_difficulty
                   when 'frequency'
                     service.cluster_by_frequency
                   when 'hierarchy'
                     service.cluster_by_hierarchy
                   else
                     []
                   end

        render json: {
          cluster_type: cluster_type,
          clusters: clusters,
          total_clusters: clusters.size
        }
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      # GET /api/v1/study_materials/:study_material_id/concepts/hierarchy
      def hierarchy
        service = ConceptClusteringService.new(@study_material)
        hierarchy = service.cluster_by_hierarchy

        render json: {
          hierarchy: hierarchy,
          total_subjects: hierarchy.size
        }
      end

      # GET /api/v1/study_materials/:study_material_id/concepts/gaps
      def gaps
        service = ConceptClusteringService.new(@study_material)
        user_ids = params[:user_ids]&.split(',')&.map(&:to_i)

        gaps = service.identify_concept_gaps(user_ids)

        render json: {
          concept_gaps: gaps,
          total_gaps: gaps.size
        }
      end

      # GET /api/v1/study_materials/:study_material_id/concepts/statistics
      def statistics
        concepts = @study_material.knowledge_nodes.active

        stats = {
          total_concepts: concepts.count,
          by_level: concepts.group(:level).count,
          by_difficulty: concepts.group(:difficulty).count,
          by_category: concepts.group(:concept_category).count,
          avg_frequency: concepts.average(:frequency)&.round(2) || 0,
          high_frequency: concepts.where('frequency >= ?', 10).count,
          untested: concepts.where(frequency: 0).count,
          with_synonyms: concepts.joins(:concept_synonyms).distinct.count,
          primary_concepts: concepts.where(is_primary: true).count
        }

        render json: { statistics: stats }
      end

      # GET /api/v1/concepts/:id/synonyms
      def synonyms
        synonyms = @concept.concept_synonyms.active

        render json: {
          concept: @concept.name,
          synonyms: synonyms.map(&:to_json_api),
          total: synonyms.count
        }
      end

      # POST /api/v1/concepts/:id/synonyms
      def add_synonym
        synonym = @concept.add_synonym(
          params[:synonym_name],
          type: params[:type] || 'synonym',
          similarity: params[:similarity]&.to_f || 1.0,
          source: params[:source] || 'manual'
        )

        if synonym.persisted?
          render json: { synonym: synonym.to_json_api }, status: :created
        else
          render json: { errors: synonym.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/concepts/:id/related
      def related
        service = ConceptClusteringService.new(@concept.study_material)
        limit = params[:limit]&.to_i || 5

        related_concepts = service.recommend_related_concepts(@concept, limit: limit)

        render json: {
          concept: @concept.to_graph_json,
          related_concepts: related_concepts,
          total: related_concepts.size
        }
      end

      # GET /api/v1/concepts/:id/questions
      def questions
        questions = @concept.questions.includes(:study_material)

        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 20, 100].min

        paginated = questions.offset((page - 1) * per_page).limit(per_page)

        render json: {
          concept: @concept.name,
          questions: paginated.map do |q|
            {
              id: q.id,
              content: q.content,
              topic: q.topic,
              difficulty: q.difficulty,
              importance: q.question_concepts.find_by(knowledge_node_id: @concept.id)&.importance_level
            }
          end,
          pagination: {
            current_page: page,
            per_page: per_page,
            total_count: questions.count,
            total_pages: (questions.count.to_f / per_page).ceil
          }
        }
      end

      # POST /api/v1/concepts/search
      def search
        query = params[:query]
        study_material_id = params[:study_material_id]

        if query.blank?
          return render json: { error: 'Query parameter is required' }, status: :bad_request
        end

        # Search by name, normalized name, or synonym
        concepts = KnowledgeNode.active
        concepts = concepts.where(study_material_id: study_material_id) if study_material_id

        # Direct match
        direct = concepts.where('LOWER(name) LIKE ? OR LOWER(normalized_name) LIKE ?',
                               "%#{query.downcase}%", "%#{query.downcase}%")

        # Synonym match
        synonym_concepts = ConceptSynonym.find_possible_concepts(query, study_material_id)

        results = direct.map { |c| c.to_graph_json(current_user) } +
                 synonym_concepts.map { |sc| KnowledgeNode.find(sc[:id]).to_graph_json(current_user) }

        render json: {
          query: query,
          results: results.uniq { |r| r[:id] },
          total: results.size
        }
      end

      # POST /api/v1/concepts/merge
      # Merge multiple concepts into one
      def merge
        source_ids = params.require(:source_ids)
        target_id = params.require(:target_id)

        if source_ids.blank? || source_ids.size < 1
          return render json: { error: 'At least one source concept is required' }, status: :bad_request
        end

        target_concept = KnowledgeNode.find(target_id)
        source_concepts = KnowledgeNode.where(id: source_ids)

        # Merge concepts
        merged_count = 0
        ActiveRecord::Base.transaction do
          source_concepts.each do |source|
            # Skip if same as target
            next if source.id == target_concept.id

            # Move all question associations to target
            source.question_concepts.update_all(knowledge_node_id: target_concept.id)

            # Move all synonyms to target
            source.concept_synonyms.update_all(knowledge_node_id: target_concept.id)

            # Add source name as synonym if not already exists
            unless target_concept.concept_synonyms.exists?(synonym_name: source.name)
              target_concept.add_synonym(source.name, type: 'merged', source: 'merge_operation')
            end

            # Merge edges (prerequisites/dependents)
            source.incoming_edges.each do |edge|
              unless target_concept.incoming_edges.exists?(from_node_id: edge.from_node_id)
                edge.update!(to_node_id: target_concept.id)
              else
                edge.destroy
              end
            end

            source.outgoing_edges.each do |edge|
              unless target_concept.outgoing_edges.exists?(to_node_id: edge.to_node_id)
                edge.update!(from_node_id: target_concept.id)
              else
                edge.destroy
              end
            end

            # Merge mastery data
            source.user_masteries.each do |mastery|
              target_mastery = target_concept.user_masteries.find_or_initialize_by(user_id: mastery.user_id)
              if target_mastery.new_record?
                target_mastery.assign_attributes(
                  mastery_level: mastery.mastery_level,
                  correct_count: mastery.correct_count,
                  total_attempts: mastery.total_attempts,
                  last_practiced_at: mastery.last_practiced_at
                )
              else
                # Merge stats
                target_mastery.correct_count += mastery.correct_count
                target_mastery.total_attempts += mastery.total_attempts
                target_mastery.mastery_level = [target_mastery.mastery_level, mastery.mastery_level].max
                target_mastery.last_practiced_at = [target_mastery.last_practiced_at, mastery.last_practiced_at].compact.max
              end
              target_mastery.save!
              mastery.destroy
            end

            # Update frequency
            target_concept.frequency = (target_concept.frequency || 0) + (source.frequency || 0)

            # Deactivate source concept
            source.update!(active: false)
            merged_count += 1
          end

          target_concept.save!
        end

        render json: {
          message: "Successfully merged #{merged_count} concepts",
          target_concept: target_concept.to_detailed_json(current_user),
          merged_count: merged_count
        }
      rescue ActiveRecord::RecordNotFound => e
        render json: { error: 'Concept not found' }, status: :not_found
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def set_study_material
        @study_material = StudyMaterial.find(params[:study_material_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Study material not found' }, status: :not_found
      end

      def set_concept
        @concept = KnowledgeNode.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Concept not found' }, status: :not_found
      end

      def concept_params
        params.require(:concept).permit(
          :name, :description, :definition, :level, :difficulty, :importance,
          :parent_name, :concept_category, :is_primary, :mastery_threshold,
          :estimated_learning_minutes, examples: [], tags: []
        )
      end

      def apply_sorting(concepts)
        sort_by = params[:sort_by] || 'name'
        order = params[:order] || 'asc'

        case sort_by
        when 'name'
          concepts.order(name: order)
        when 'frequency'
          concepts.order(frequency: order)
        when 'difficulty'
          concepts.order(difficulty: order)
        when 'importance'
          concepts.order(importance: order)
        when 'created_at'
          concepts.order(created_at: order)
        else
          concepts
        end
      end
    end
  end
end
