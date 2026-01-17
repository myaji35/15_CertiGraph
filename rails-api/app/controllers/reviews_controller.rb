class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:index, :create]
  before_action :set_review, only: [:show, :update, :destroy, :vote, :remove_vote]

  # GET /study_materials/:study_material_id/reviews
  def index
    reviews = @study_material.reviews
      .includes(:user, :review_votes)
      .order(created_at: :desc)

    # Filtering
    reviews = reviews.with_rating(params[:rating]) if params[:rating].present?
    reviews = reviews.verified if params[:verified] == 'true'

    # Sorting
    case params[:sort_by]
    when 'helpful'
      reviews = reviews.helpful
    when 'rating_high'
      reviews = reviews.order(rating: :desc)
    when 'rating_low'
      reviews = reviews.order(rating: :asc)
    when 'recent'
      reviews = reviews.recent
    else
      reviews = reviews.recent
    end

    # Pagination
    page = (params[:page] || 1).to_i
    per_page = [(params[:per_page] || 20).to_i, 100].min
    reviews = reviews.offset((page - 1) * per_page).limit(per_page)

    render json: {
      reviews: reviews.map { |r| review_json(r) },
      pagination: {
        page: page,
        per_page: per_page,
        total: @study_material.reviews.count
      },
      summary: {
        avg_rating: @study_material.avg_rating,
        total_reviews: @study_material.total_reviews,
        rating_distribution: @study_material.rating_distribution
      }
    }
  end

  # GET /reviews/:id
  def show
    render json: review_json(@review)
  end

  # POST /study_materials/:study_material_id/reviews
  def create
    # Check if user has already reviewed
    if @study_material.reviewed_by?(current_user)
      return render json: { error: '이미 이 자료에 대한 리뷰를 작성하셨습니다' }, status: :unprocessable_entity
    end

    # Check if user has purchased (for paid materials)
    if !@study_material.free? && !@study_material.purchased_by?(current_user)
      return render json: { error: '구매한 자료만 리뷰를 작성할 수 있습니다' }, status: :forbidden
    end

    review = @study_material.reviews.build(review_params)
    review.user = current_user
    review.verified_purchase = @study_material.purchased_by?(current_user)

    if review.save
      render json: {
        message: '리뷰가 작성되었습니다',
        review: review_json(review)
      }, status: :created
    else
      render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /reviews/:id
  def update
    unless @review.user_id == current_user.id
      return render json: { error: '권한이 없습니다' }, status: :forbidden
    end

    if @review.update(review_params)
      render json: {
        message: '리뷰가 수정되었습니다',
        review: review_json(@review)
      }
    else
      render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /reviews/:id
  def destroy
    unless @review.user_id == current_user.id || current_user.admin?
      return render json: { error: '권한이 없습니다' }, status: :forbidden
    end

    @review.destroy
    render json: { message: '리뷰가 삭제되었습니다' }
  end

  # POST /reviews/:id/vote
  def vote
    helpful = params[:helpful] == 'true' || params[:helpful] == true

    begin
      @review.vote!(current_user, helpful)
      render json: {
        message: '투표가 완료되었습니다',
        review: review_json(@review)
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # DELETE /reviews/:id/vote
  def remove_vote
    begin
      @review.remove_vote!(current_user)
      render json: {
        message: '투표가 취소되었습니다',
        review: review_json(@review)
      }
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # GET /reviews/my_reviews
  def my_reviews
    reviews = current_user.reviews
      .includes(:study_material)
      .order(created_at: :desc)

    page = (params[:page] || 1).to_i
    per_page = [(params[:per_page] || 20).to_i, 100].min
    reviews = reviews.offset((page - 1) * per_page).limit(per_page)

    render json: {
      reviews: reviews.map { |r| review_json(r) },
      pagination: {
        page: page,
        per_page: per_page,
        total: current_user.reviews.count
      }
    }
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '자료를 찾을 수 없습니다' }, status: :not_found
  end

  def set_review
    @review = Review.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '리뷰를 찾을 수 없습니다' }, status: :not_found
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end

  def review_json(review)
    {
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      helpful_count: review.helpful_count,
      not_helpful_count: review.not_helpful_count,
      helpful_percentage: review.helpful_percentage,
      verified_purchase: review.verified_purchase,
      user: {
        id: review.user.id,
        name: review.user.name
      },
      study_material: {
        id: review.study_material.id,
        name: review.study_material.name
      },
      user_voted: current_user ? {
        helpful: review.user_voted?(current_user, true),
        not_helpful: review.user_voted?(current_user, false)
      } : nil,
      created_at: review.created_at,
      updated_at: review.updated_at
    }
  end
end
