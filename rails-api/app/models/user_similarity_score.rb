# app/models/user_similarity_score.rb
class UserSimilarityScore < ApplicationRecord
  belongs_to :user
  belongs_to :similar_user, class_name: 'User'

  validates :similarity_score, presence: true,
            numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0 }
  validates :similarity_type, presence: true,
            inclusion: { in: %w[cosine pearson jaccard euclidean] }

  scope :for_user, ->(user) { where(user: user) }
  scope :high_similarity, -> { where('similarity_score >= ?', 70.0) }
  scope :recent, ->(days = 30) { where('calculated_at >= ?', days.days.ago) }
  scope :by_similarity, -> { order(similarity_score: :desc) }

  # Find similar users for a given user
  def self.find_similar_users(user, limit: 10, min_similarity: 50.0)
    where(user: user)
      .where('similarity_score >= ?', min_similarity)
      .order(similarity_score: :desc)
      .limit(limit)
      .includes(:similar_user)
  end

  # Calculate and store similarity between two users
  def self.calculate_and_store(user1, user2, type: 'cosine')
    # Get mastery data for both users
    masteries1 = user1.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h
    masteries2 = user2.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h

    # Calculate similarity based on type
    similarity = case type
                when 'cosine'
                  calculate_cosine_similarity(masteries1, masteries2)
                when 'pearson'
                  calculate_pearson_correlation(masteries1, masteries2)
                when 'jaccard'
                  calculate_jaccard_similarity(masteries1, masteries2)
                else
                  0.0
                end

    common_concepts = (masteries1.keys & masteries2.keys).size

    # Store or update similarity score
    find_or_initialize_by(user: user1, similar_user: user2).tap do |score|
      score.similarity_score = similarity
      score.similarity_type = type
      score.common_concepts_count = common_concepts
      score.calculated_at = Time.current
      score.similarity_breakdown = {
        total_concepts_user1: masteries1.size,
        total_concepts_user2: masteries2.size,
        common_concepts: common_concepts
      }
      score.save!
    end
  end

  # Cosine similarity calculation
  def self.calculate_cosine_similarity(vec1, vec2)
    common_keys = vec1.keys & vec2.keys
    return 0.0 if common_keys.empty?

    dot_product = common_keys.sum { |k| vec1[k] * vec2[k] }
    magnitude1 = Math.sqrt(vec1.values.sum { |v| v**2 })
    magnitude2 = Math.sqrt(vec2.values.sum { |v| v**2 })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    (dot_product / (magnitude1 * magnitude2) * 100).round(2)
  end

  # Pearson correlation calculation
  def self.calculate_pearson_correlation(vec1, vec2)
    common_keys = vec1.keys & vec2.keys
    return 0.0 if common_keys.size < 2

    n = common_keys.size
    sum1 = common_keys.sum { |k| vec1[k] }
    sum2 = common_keys.sum { |k| vec2[k] }
    sum1_sq = common_keys.sum { |k| vec1[k]**2 }
    sum2_sq = common_keys.sum { |k| vec2[k]**2 }
    sum_products = common_keys.sum { |k| vec1[k] * vec2[k] }

    numerator = sum_products - (sum1 * sum2 / n)
    denominator = Math.sqrt((sum1_sq - sum1**2 / n) * (sum2_sq - sum2**2 / n))

    return 0.0 if denominator.zero?

    ((numerator / denominator) * 100).round(2)
  end

  # Jaccard similarity calculation
  def self.calculate_jaccard_similarity(vec1, vec2)
    keys1 = vec1.keys.to_set
    keys2 = vec2.keys.to_set

    intersection = (keys1 & keys2).size
    union = (keys1 | keys2).size

    return 0.0 if union.zero?

    (intersection.to_f / union * 100).round(2)
  end

  # Batch calculate similarities for a user
  def self.batch_calculate_for_user(user, type: 'cosine', limit: 50)
    # Find users with similar activity
    candidate_users = User.joins(:user_masteries)
                         .where.not(id: user.id)
                         .group('users.id')
                         .having('COUNT(user_masteries.id) >= ?', 5)
                         .limit(limit)

    candidate_users.each do |other_user|
      calculate_and_store(user, other_user, type: type)
    end
  end
end
