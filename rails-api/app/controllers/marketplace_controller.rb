class MarketplaceController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show, :search, :facets, :popular, :top_rated, :recent]
  before_action :set_material, only: [:show, :purchase, :toggle_publish]

  # GET /marketplace
  def index
    service = MarketplaceSearchService.new(search_params, current_user)
    materials = service.search

    render json: {
      materials: materials.map { |m| material_summary(m) },
      pagination: {
        page: (params[:page] || 1).to_i,
        per_page: [(params[:per_page] || 20).to_i, 100].min,
        total: StudyMaterial.published.count
      }
    }
  end

  # GET /marketplace/search
  def search
    service = MarketplaceSearchService.new(search_params, current_user)
    materials = service.search

    render json: {
      results: materials.map { |m| material_summary(m) },
      count: materials.count,
      query: params[:q]
    }
  end

  # GET /marketplace/facets
  def facets
    service = MarketplaceSearchService.new({}, current_user)
    render json: service.facets
  end

  # GET /marketplace/:id
  def show
    if @material.can_access?(current_user) || @material.is_public?
      render json: material_detail(@material)
    else
      render json: { error: '접근 권한이 없습니다' }, status: :forbidden
    end
  end

  # GET /marketplace/popular
  def popular
    materials = StudyMaterial.published.popular.limit(params[:limit] || 10)
    render json: materials.map { |m| material_summary(m) }
  end

  # GET /marketplace/top_rated
  def top_rated
    materials = StudyMaterial.published.top_rated.limit(params[:limit] || 10)
    render json: materials.map { |m| material_summary(m) }
  end

  # GET /marketplace/recent
  def recent
    materials = StudyMaterial.published.recent.limit(params[:limit] || 10)
    render json: materials.map { |m| material_summary(m) }
  end

  # GET /marketplace/categories
  def categories
    categories = StudyMaterial.published.where.not(category: nil).distinct.pluck(:category)
    render json: { categories: categories }
  end

  # GET /marketplace/my_materials
  def my_materials
    materials = current_user.study_sets
      .joins(:study_materials)
      .select('study_materials.*')
      .distinct

    render json: materials.map { |m| material_summary(m) }
  end

  # GET /marketplace/purchased
  def purchased
    purchases = current_user.purchases.completed.includes(study_material: :study_set)

    render json: purchases.map do |purchase|
      {
        id: purchase.id,
        material: material_summary(purchase.study_material),
        purchased_at: purchase.purchased_at,
        price: purchase.price,
        download_count: purchase.download_count,
        download_limit: purchase.download_limit,
        remaining_downloads: purchase.remaining_downloads,
        expires_at: purchase.expires_at,
        can_download: purchase.can_download?
      }
    end
  end

  # POST /marketplace/:id/purchase
  def purchase
    if @material.free?
      # Create free purchase
      purchase = Purchase.create!(
        user: current_user,
        study_material: @material,
        price: 0,
        status: 'completed',
        purchased_at: Time.current
      )

      render json: {
        message: '무료 자료를 성공적으로 받았습니다',
        purchase: purchase
      }
    else
      # For paid materials, integrate with payment service
      if params[:payment_id].blank?
        return render json: { error: '결제 정보가 필요합니다' }, status: :unprocessable_entity
      end

      payment = Payment.find_by(id: params[:payment_id], user: current_user)
      unless payment&.status == 'approved'
        return render json: { error: '유효하지 않은 결제입니다' }, status: :unprocessable_entity
      end

      purchase = Purchase.create!(
        user: current_user,
        study_material: @material,
        payment: payment,
        price: @material.price,
        status: 'completed',
        purchased_at: Time.current
      )

      render json: {
        message: '구매가 완료되었습니다',
        purchase: purchase
      }
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /marketplace/:id/toggle_publish
  def toggle_publish
    unless @material.study_set.user_id == current_user.id
      return render json: { error: '권한이 없습니다' }, status: :forbidden
    end

    if @material.is_public?
      @material.unpublish!
      message = '자료를 비공개로 전환했습니다'
    else
      # Validate required fields before publishing
      if @material.category.blank?
        return render json: { error: '카테고리를 설정해야 합니다' }, status: :unprocessable_entity
      end

      @material.publish!
      message = '자료를 마켓플레이스에 공개했습니다'
    end

    render json: {
      message: message,
      material: material_summary(@material)
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # PATCH /marketplace/:id/update_listing
  def update_listing
    material = StudyMaterial.find(params[:id])

    unless material.study_set.user_id == current_user.id
      return render json: { error: '권한이 없습니다' }, status: :forbidden
    end

    if material.update(listing_params)
      render json: {
        message: '자료 정보가 업데이트되었습니다',
        material: material_summary(material)
      }
    else
      render json: { errors: material.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /marketplace/:id/download
  def download
    material = StudyMaterial.find(params[:id])

    unless material.can_access?(current_user)
      return render json: { error: '접근 권한이 없습니다' }, status: :forbidden
    end

    purchase = Purchase.find_by(user: current_user, study_material: material)

    if purchase && !purchase.can_download?
      return render json: { error: '다운로드 한도를 초과했습니다' }, status: :forbidden
    end

    purchase&.download!

    if material.pdf_file.attached?
      redirect_to rails_blob_path(material.pdf_file, disposition: "attachment")
    else
      render json: { error: 'PDF 파일이 없습니다' }, status: :not_found
    end
  end

  # GET /marketplace/stats
  def stats
    render json: {
      total_materials: StudyMaterial.published.count,
      free_materials: StudyMaterial.free.count,
      paid_materials: StudyMaterial.paid.count,
      total_sales: Purchase.completed.count,
      total_revenue: Purchase.completed.sum(:price),
      avg_rating: StudyMaterial.published.average(:avg_rating).to_f.round(2),
      categories_count: StudyMaterial.published.distinct.count(:category)
    }
  end

  private

  def set_material
    @material = StudyMaterial.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '자료를 찾을 수 없습니다' }, status: :not_found
  end

  def search_params
    params.permit(
      :q, :category, :difficulty, :certification, :price_type,
      :min_price, :max_price, :min_rating, :min_questions, :max_questions,
      :sort_by, :page, :per_page, :exclude_own,
      tags: []
    )
  end

  def listing_params
    params.require(:material).permit(
      :price, :category, :difficulty_level, :is_public,
      tags: []
    )
  end

  def material_summary(material)
    {
      id: material.id,
      name: material.name,
      category: material.category,
      difficulty_level: material.difficulty_level,
      price: material.price,
      is_public: material.is_public,
      avg_rating: material.avg_rating,
      total_reviews: material.total_reviews,
      sales_count: material.sales_count,
      total_questions: material.total_questions,
      tags: material.tags,
      published_at: material.published_at,
      free: material.free?,
      certification: material.study_set&.certification,
      owner: {
        id: material.study_set&.user_id,
        name: material.study_set&.user&.name
      }
    }
  end

  def material_detail(material)
    result = material_summary(material).merge(
      description: material.study_set&.description,
      exam_date: material.study_set&.exam_date,
      status: material.status,
      created_at: material.created_at,
      updated_at: material.updated_at,
      rating_distribution: material.rating_distribution,
      reviews: material.reviews.recent.limit(10).map do |review|
        {
          id: review.id,
          rating: review.rating,
          comment: review.comment,
          helpful_count: review.helpful_count,
          verified_purchase: review.verified_purchase,
          user_name: review.user.name,
          created_at: review.created_at
        }
      end
    )

    if current_user
      result[:purchased] = material.purchased_by?(current_user)
      result[:reviewed] = material.reviewed_by?(current_user)
    end

    result
  end
end
