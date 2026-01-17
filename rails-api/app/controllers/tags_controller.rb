class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :update, :destroy]
  before_action :authenticate_user!, except: [:index, :show]

  # GET /tags
  # List all tags with optional filtering
  def index
    @tags = Tag.all

    # Filter by category
    @tags = @tags.by_category(params[:category]) if params[:category].present?

    # Filter by context
    @tags = @tags.for_context(params[:context]) if params[:context].present?

    # Search by name
    if params[:search].present?
      @tags = @tags.where('name LIKE ?', "%#{params[:search]}%")
    end

    # Sorting
    @tags = case params[:sort]
    when 'popular'
      @tags.popular
    when 'recent'
      @tags.recent
    when 'alphabetical'
      @tags.alphabetical
    else
      @tags.popular
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    @tags = @tags.limit(per_page).offset((page - 1) * per_page)

    render json: {
      tags: @tags.map { |tag| tag_json(tag) },
      meta: {
        page: page,
        per_page: per_page,
        total: Tag.count
      }
    }
  end

  # GET /tags/:id
  # Get a specific tag with statistics
  def show
    render json: {
      tag: tag_json(@tag, include_stats: true),
      study_materials: @tag.study_materials.limit(10).map { |sm| study_material_summary(sm) }
    }
  end

  # POST /tags
  # Create a new tag
  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      render json: {
        message: 'Tag created successfully',
        tag: tag_json(@tag)
      }, status: :created
    else
      render json: {
        error: 'Failed to create tag',
        errors: @tag.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /tags/:id
  # Update a tag
  def update
    if @tag.update(tag_params)
      render json: {
        message: 'Tag updated successfully',
        tag: tag_json(@tag)
      }
    else
      render json: {
        error: 'Failed to update tag',
        errors: @tag.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /tags/:id
  # Delete a tag
  def destroy
    @tag.destroy
    render json: { message: 'Tag deleted successfully' }
  end

  # GET /tags/popular
  # Get most popular tags
  def popular
    limit = params[:limit]&.to_i || 20
    @tags = Tag.most_used(limit)

    render json: {
      tags: @tags.map { |tag| tag_json(tag, include_stats: true) }
    }
  end

  # GET /tags/contexts
  # Get all available tag contexts
  def contexts
    contexts = Tagging.contexts

    render json: {
      contexts: contexts,
      counts: contexts.map { |context|
        {
          context: context,
          count: Tagging.by_context(context).count
        }
      }
    }
  end

  # POST /tags/apply
  # Apply tags to a study material
  def apply
    study_material = StudyMaterial.find(params[:study_material_id])

    tag_names = params[:tags] || []
    context = params[:context] || 'manual'

    applied_tags = []

    tag_names.each do |tag_name|
      tag = Tag.find_or_create_by_name(tag_name)

      tagging = Tagging.find_or_create_by(
        tag: tag,
        taggable: study_material
      ) do |t|
        t.context = context
        t.relevance_score = params[:relevance_score] || 100
      end

      applied_tags << tag if tagging.persisted?
    end

    render json: {
      message: "Applied #{applied_tags.count} tags",
      tags: applied_tags.map { |tag| tag_json(tag) },
      study_material: study_material_summary(study_material)
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # DELETE /tags/remove
  # Remove tags from a study material
  def remove
    study_material = StudyMaterial.find(params[:study_material_id])
    tag_ids = params[:tag_ids] || []

    removed_count = Tagging.where(
      taggable: study_material,
      tag_id: tag_ids
    ).destroy_all.count

    render json: {
      message: "Removed #{removed_count} tags",
      study_material: study_material_summary(study_material)
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /tags/auto_tag
  # Auto-generate tags for a study material
  def auto_tag
    study_material = StudyMaterial.find(params[:study_material_id])

    service = AutoTaggingService.new(study_material)

    if service.generate_tags
      render json: {
        message: 'Tags generated successfully',
        tags: study_material.tags.map { |tag| tag_json(tag) },
        study_material: study_material_summary(study_material)
      }
    else
      render json: {
        error: 'Failed to generate tags',
        errors: service.errors
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # GET /tags/search
  # Search tags by name or metadata
  def search
    query = params[:q]

    if query.blank?
      return render json: { tags: [] }
    end

    @tags = Tag.where('name LIKE ?', "%#{query}%")
      .or(Tag.where("json_extract(metadata, '$.keywords') LIKE ?", "%#{query}%"))
      .limit(20)

    render json: {
      tags: @tags.map { |tag| tag_json(tag) },
      query: query
    }
  end

  # POST /tags/merge
  # Merge multiple tags into one
  def merge
    return render json: { error: 'Admin access required' }, status: :forbidden unless current_user.admin?

    source_tag_ids = params[:source_tag_ids] || []
    target_tag_id = params[:target_tag_id]

    source_tags = Tag.where(id: source_tag_ids)
    target_tag = Tag.find(target_tag_id)

    merged_count = 0

    source_tags.each do |source_tag|
      source_tag.taggings.each do |tagging|
        # Move tagging to target tag if it doesn't exist
        unless Tagging.exists?(tag: target_tag, taggable: tagging.taggable)
          tagging.update(tag: target_tag)
          merged_count += 1
        end
      end
      source_tag.destroy
    end

    render json: {
      message: "Merged #{merged_count} taggings into '#{target_tag.name}'",
      tag: tag_json(target_tag, include_stats: true)
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Tag not found' }, status: :not_found
  end

  def tag_params
    params.require(:tag).permit(:name, :category, metadata: {})
  end

  def tag_json(tag, include_stats: false)
    json = {
      id: tag.id,
      name: tag.name,
      display_name: tag.display_name,
      category: tag.category,
      usage_count: tag.usage_count,
      created_at: tag.created_at,
      updated_at: tag.updated_at
    }

    if include_stats
      json[:stats] = tag.tagging_stats
    end

    json
  end

  def study_material_summary(material)
    {
      id: material.id,
      name: material.name,
      category: material.category,
      difficulty: material.difficulty,
      status: material.status,
      tags_count: material.tags.count
    }
  end

  def authenticate_user!
    # Implement your authentication logic here
    # For now, we'll skip authentication
    # In production, use JWT or session-based auth
  end

  def current_user
    # Return current authenticated user
    # For now, return nil or mock user
    nil
  end
end
