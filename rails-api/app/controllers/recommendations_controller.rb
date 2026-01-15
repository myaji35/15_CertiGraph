# app/controllers/recommendations_controller.rb
class RecommendationsController < ApplicationController
  before_action :authenticate_user!

  # GET /recommendations
  def index
    study_set_id = params[:study_set_id]
    recommendation_type = params[:type] || 'all'

    recommendations = if study_set_id
                        current_user.learning_recommendations
                                   .where(study_set_id: study_set_id)
                      else
                        current_user.learning_recommendations
                      end

    recommendations = recommendations.where(recommendation_type: recommendation_type) unless recommendation_type == 'all'
    recommendations = recommendations.where(status: 'pending').order(priority_level: :desc, created_at: :desc)

    render json: {
      success: true,
      recommendations: recommendations.as_json(include: [:study_set, :analysis_result]),
      count: recommendations.count
    }
  end

  # GET /recommendations/:id
  def show
    recommendation = current_user.learning_recommendations.find(params[:id])

    render json: {
      success: true,
      recommendation: recommendation.as_json(
        include: {
          study_set: { only: [:id, :title] },
          analysis_result: { only: [:id, :analysis_type, :concept_gap_score] }
        }
      )
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/generate
  def generate
    study_set_id = params[:study_set_id]
    force_regenerate = params[:force] == 'true'

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    # Generate recommendations
    recommendations = engine.generate_recommendations(force: force_regenerate)

    render json: {
      success: true,
      message: 'Recommendations generated successfully',
      recommendations: recommendations.as_json,
      count: recommendations.size
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Recommendation generation failed: #{e.message}"
    render json: { error: 'Failed to generate recommendations' }, status: :internal_server_error
  end

  # GET /recommendations/learning_path
  def learning_path
    study_set_id = params[:study_set_id]

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    learning_path = engine.generate_learning_path

    render json: {
      success: true,
      learning_path: learning_path
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error "Learning path generation failed: #{e.message}"
    render json: { error: 'Failed to generate learning path' }, status: :internal_server_error
  end

  # POST /recommendations/:id/accept
  def accept
    recommendation = current_user.learning_recommendations.find(params[:id])

    recommendation.update!(
      status: 'in_progress',
      is_accepted: true,
      started_at: Time.current
    )

    render json: {
      success: true,
      recommendation: recommendation,
      message: 'Recommendation accepted'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/:id/complete
  def complete
    recommendation = current_user.learning_recommendations.find(params[:id])
    feedback_rating = params[:rating]&.to_i
    feedback_text = params[:feedback]

    recommendation.update!(
      status: 'completed',
      completed_at: Time.current,
      feedback_rating: feedback_rating,
      user_feedback: feedback_text
    )

    render json: {
      success: true,
      recommendation: recommendation,
      message: 'Recommendation completed'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # POST /recommendations/:id/dismiss
  def dismiss
    recommendation = current_user.learning_recommendations.find(params[:id])

    recommendation.update!(
      status: 'dismissed',
      user_feedback: params[:reason]
    )

    render json: {
      success: true,
      message: 'Recommendation dismissed'
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Recommendation not found' }, status: :not_found
  end

  # GET /recommendations/personalized
  def personalized
    study_set_id = params[:study_set_id]
    limit = (params[:limit] || 10).to_i

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    recommendations = engine.personalized_recommendations(limit: limit)

    render json: {
      success: true,
      recommendations: recommendations,
      explanation: engine.recommendation_explanation
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  # GET /recommendations/similar_users
  def similar_users
    engine = RecommendationEngine.new(current_user)
    similar_users_data = engine.find_similar_users(limit: 10)

    render json: {
      success: true,
      similar_users: similar_users_data
    }
  end

  # GET /recommendations/trending
  def trending
    study_set_id = params[:study_set_id]
    limit = (params[:limit] || 10).to_i

    trending_items = if study_set_id
                       RecommendationEngine.trending_in_study_set(study_set_id, limit: limit)
                     else
                       RecommendationEngine.global_trending(limit: limit)
                     end

    render json: {
      success: true,
      trending: trending_items
    }
  end

  # GET /recommendations/next_steps
  def next_steps
    study_set_id = params[:study_set_id]

    unless study_set_id
      return render json: { error: 'study_set_id is required' }, status: :bad_request
    end

    study_set = current_user.study_sets.find(study_set_id)
    engine = RecommendationEngine.new(current_user, study_set)

    next_steps = engine.suggest_next_steps

    render json: {
      success: true,
      next_steps: next_steps
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Study set not found' }, status: :not_found
  end

  # POST /recommendations/batch_generate
  def batch_generate
    # Queue job to generate recommendations for all study sets
    UpdateRecommendationsJob.perform_later(current_user.id)

    render json: {
      success: true,
      message: 'Batch recommendation generation started'
    }
  end

  private

  def recommendation_params
    params.permit(:study_set_id, :type, :force, :limit, :rating, :feedback, :reason)
  end
end
