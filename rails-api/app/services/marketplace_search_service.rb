class MarketplaceSearchService
  attr_reader :params, :user

  def initialize(params = {}, user = nil)
    @params = params
    @user = user
  end

  def search
    materials = StudyMaterial.published.includes(:study_set, :reviews)

    # Text search (searches in name, description, tags)
    materials = apply_text_search(materials) if params[:q].present?

    # Category filter
    materials = materials.by_category(params[:category]) if params[:category].present?

    # Difficulty filter
    materials = materials.by_difficulty(params[:difficulty]) if params[:difficulty].present?

    # Certification filter
    materials = materials.by_certification(params[:certification]) if params[:certification].present?

    # Price filters
    materials = apply_price_filters(materials)

    # Rating filter
    materials = materials.with_min_rating(params[:min_rating]) if params[:min_rating].present?

    # Tag filter
    materials = apply_tag_filter(materials) if params[:tags].present?

    # Free/Paid filter
    materials = apply_price_type_filter(materials) if params[:price_type].present?

    # Question count filter
    materials = apply_question_count_filter(materials) if params[:min_questions].present? || params[:max_questions].present?

    # Owner filter (exclude own materials)
    materials = materials.where.not(study_sets: { user_id: user.id }) if params[:exclude_own] == 'true' && user.present?

    # Sorting
    materials = apply_sorting(materials)

    # Pagination
    apply_pagination(materials)
  end

  def facets
    {
      categories: get_categories_facet,
      difficulty_levels: get_difficulty_facet,
      certifications: get_certifications_facet,
      price_ranges: get_price_ranges_facet,
      rating_distribution: get_rating_distribution_facet,
      total_count: StudyMaterial.published.count
    }
  end

  private

  def apply_text_search(materials)
    query = "%#{params[:q]}%"
    materials.where(
      "study_materials.name LIKE ? OR study_materials.category LIKE ?",
      query, query
    ).or(
      materials.where("json_extract(study_materials.tags, '$') LIKE ?", query)
    )
  end

  def apply_price_filters(materials)
    if params[:min_price].present? || params[:max_price].present?
      min_price = params[:min_price].to_f || 0
      max_price = params[:max_price].to_f || Float::INFINITY
      materials = materials.by_price_range(min_price, max_price)
    end
    materials
  end

  def apply_price_type_filter(materials)
    case params[:price_type]
    when 'free'
      materials.free
    when 'paid'
      materials.paid
    else
      materials
    end
  end

  def apply_tag_filter(materials)
    tags = params[:tags].is_a?(Array) ? params[:tags] : [params[:tags]]
    tags.each do |tag|
      materials = materials.where("json_extract(study_materials.tags, '$') LIKE ?", "%#{tag}%")
    end
    materials
  end

  def apply_question_count_filter(materials)
    materials = materials.joins(:questions).group('study_materials.id')

    if params[:min_questions].present?
      materials = materials.having('COUNT(questions.id) >= ?', params[:min_questions].to_i)
    end

    if params[:max_questions].present?
      materials = materials.having('COUNT(questions.id) <= ?', params[:max_questions].to_i)
    end

    materials
  end

  def apply_sorting(materials)
    sort_by = params[:sort_by] || 'popular'

    case sort_by
    when 'popular'
      materials.popular
    when 'recent'
      materials.recent
    when 'price_low'
      materials.order(price: :asc)
    when 'price_high'
      materials.order(price: :desc)
    when 'rating'
      materials.top_rated
    when 'sales'
      materials.order(sales_count: :desc)
    when 'name'
      materials.order(name: :asc)
    else
      materials.popular
    end
  end

  def apply_pagination(materials)
    page = (params[:page] || 1).to_i
    per_page = [(params[:per_page] || 20).to_i, 100].min # Max 100 per page

    materials.offset((page - 1) * per_page).limit(per_page)
  end

  def get_categories_facet
    StudyMaterial.published
      .where.not(category: nil)
      .group(:category)
      .count
  end

  def get_difficulty_facet
    StudyMaterial.published
      .where.not(difficulty_level: nil)
      .group(:difficulty_level)
      .count
  end

  def get_certifications_facet
    StudyMaterial.published
      .joins(:study_set)
      .where.not(study_sets: { certification: nil })
      .group('study_sets.certification')
      .count
  end

  def get_price_ranges_facet
    {
      free: StudyMaterial.free.count,
      under_10000: StudyMaterial.published.where('price > 0 AND price < 10000').count,
      '10000_to_30000': StudyMaterial.published.where('price >= 10000 AND price < 30000').count,
      '30000_to_50000': StudyMaterial.published.where('price >= 30000 AND price < 50000').count,
      over_50000: StudyMaterial.published.where('price >= 50000').count
    }
  end

  def get_rating_distribution_facet
    StudyMaterial.published
      .where('avg_rating > 0')
      .group('CAST(avg_rating AS INTEGER)')
      .count
  end
end
