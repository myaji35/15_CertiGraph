# app/services/collaborative_filtering_service.rb
class CollaborativeFilteringService
  attr_reader :user, :study_set

  def initialize(user, study_set = nil)
    @user = user
    @study_set = study_set
  end

  # Generate user-based collaborative filtering recommendations
  def user_based_recommendations(limit: 10, min_similarity: 60.0)
    # Find similar users
    similar_users = find_similar_users(min_similarity: min_similarity)

    return [] if similar_users.empty?

    # Get questions that similar users practiced successfully
    recommended_questions = questions_from_similar_users(similar_users, limit: limit * 2)

    # Score and rank questions
    scored_questions = score_questions_by_similarity(recommended_questions, similar_users)

    # Return top recommendations
    scored_questions.take(limit).map do |q|
      {
        question_id: q[:question_id],
        score: q[:cf_score],
        reason: "#{q[:similar_users_count]}명의 유사 학습자가 이 문제를 성공적으로 풀었습니다",
        algorithm: 'user_based_cf',
        confidence: calculate_confidence(q[:similar_users_count], similar_users.size),
        metadata: {
          similar_users_count: q[:similar_users_count],
          avg_success_rate: q[:avg_success_rate],
          similar_users: similar_users.take(3).map { |u| u[:user_id] }
        }
      }
    end
  end

  # Generate item-based collaborative filtering recommendations
  def item_based_recommendations(limit: 10)
    # Get questions user has answered correctly
    user_correct_questions = get_user_correct_questions

    return [] if user_correct_questions.empty?

    # Find similar questions (questions answered by same users)
    similar_questions = find_similar_questions(user_correct_questions, limit: limit * 2)

    # Score and rank
    scored_questions = score_items_by_similarity(similar_questions, user_correct_questions)

    scored_questions.take(limit).map do |q|
      {
        question_id: q[:question_id],
        score: q[:cf_score],
        reason: "당신이 푼 문제와 유사한 패턴의 문제입니다",
        algorithm: 'item_based_cf',
        confidence: q[:confidence],
        metadata: {
          similarity_score: q[:similarity_score],
          based_on_questions: q[:based_on_questions].take(3)
        }
      }
    end
  end

  # Hybrid: Combine user-based and item-based CF
  def hybrid_cf_recommendations(limit: 10, user_weight: 0.6, item_weight: 0.4)
    user_recs = user_based_recommendations(limit: limit * 2)
    item_recs = item_based_recommendations(limit: limit * 2)

    # Combine and reweight scores
    combined = {}

    user_recs.each do |rec|
      combined[rec[:question_id]] = {
        question_id: rec[:question_id],
        cf_score: rec[:score] * user_weight,
        user_score: rec[:score],
        item_score: 0.0,
        reasons: [rec[:reason]],
        metadata: rec[:metadata]
      }
    end

    item_recs.each do |rec|
      if combined[rec[:question_id]]
        combined[rec[:question_id]][:cf_score] += rec[:score] * item_weight
        combined[rec[:question_id]][:item_score] = rec[:score]
        combined[rec[:question_id]][:reasons] << rec[:reason]
      else
        combined[rec[:question_id]] = {
          question_id: rec[:question_id],
          cf_score: rec[:score] * item_weight,
          user_score: 0.0,
          item_score: rec[:score],
          reasons: [rec[:reason]],
          metadata: rec[:metadata]
        }
      end
    end

    # Sort by combined score
    combined.values.sort_by { |r| -r[:cf_score] }.take(limit).map do |rec|
      {
        question_id: rec[:question_id],
        score: rec[:cf_score],
        reason: rec[:reasons].join(' + '),
        algorithm: 'hybrid_cf',
        confidence: calculate_hybrid_confidence(rec[:user_score], rec[:item_score]),
        metadata: rec[:metadata].merge(
          user_cf_score: rec[:user_score],
          item_cf_score: rec[:item_score]
        )
      }
    end
  end

  # Find similar users using pre-calculated similarity scores
  def find_similar_users(min_similarity: 60.0, limit: 20)
    # Try to use cached similarity scores
    cached_scores = UserSimilarityScore.find_similar_users(
      user,
      limit: limit,
      min_similarity: min_similarity
    )

    if cached_scores.any?
      return cached_scores.map do |score|
        {
          user_id: score.similar_user_id,
          similarity_score: score.similarity_score,
          common_concepts: score.common_concepts_count
        }
      end
    end

    # If no cached scores, calculate on-the-fly
    calculate_similar_users_on_fly(min_similarity: min_similarity, limit: limit)
  end

  # Calculate user similarity on-the-fly
  def calculate_similar_users_on_fly(min_similarity: 60.0, limit: 20)
    user_masteries = user.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h
    return [] if user_masteries.empty?

    # Find candidate users
    candidate_users = User.joins(:user_masteries)
                         .where.not(id: user.id)
                         .group('users.id')
                         .having('COUNT(user_masteries.id) >= ?', [user_masteries.size * 0.3, 5].max)
                         .limit(limit * 3)

    similar_users = candidate_users.map do |other_user|
      other_masteries = other_user.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h
      similarity = calculate_cosine_similarity(user_masteries, other_masteries)

      next if similarity < min_similarity

      {
        user_id: other_user.id,
        similarity_score: similarity,
        common_concepts: (user_masteries.keys & other_masteries.keys).size
      }
    end.compact

    similar_users.sort_by { |u| -u[:similarity_score] }.take(limit)
  end

  # Get questions practiced successfully by similar users
  def questions_from_similar_users(similar_users, limit: 20)
    return [] if similar_users.empty?

    similar_user_ids = similar_users.map { |u| u[:user_id] }

    # Get questions answered correctly by similar users
    question_stats = TestAnswer.joins(:test_question, test_question: :test_session)
                              .where(test_sessions: { user_id: similar_user_ids })
                              .where(is_correct: true)
                              .group('test_questions.question_id')
                              .select(
                                'test_questions.question_id',
                                'COUNT(DISTINCT test_sessions.user_id) as user_count',
                                'AVG(CASE WHEN test_answers.is_correct THEN 1.0 ELSE 0.0 END) as success_rate'
                              )
                              .having('user_count >= ?', [similar_users.size * 0.3, 2].max)

    # Filter to study set if specified
    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      question_stats = question_stats.joins('INNER JOIN questions ON questions.id = test_questions.question_id')
                                    .where(questions: { study_material_id: material_ids })
    end

    # Exclude questions already answered by current user
    answered_question_ids = user.test_answers.joins(:test_question)
                               .pluck('test_questions.question_id').uniq
    question_stats = question_stats.where.not('test_questions.question_id': answered_question_ids)

    question_stats.limit(limit).map do |stat|
      {
        question_id: stat.question_id,
        similar_users_count: stat.user_count,
        avg_success_rate: stat.success_rate
      }
    end
  end

  # Score questions based on similar user preferences
  def score_questions_by_similarity(questions, similar_users)
    questions.map do |q|
      # Calculate CF score based on:
      # 1. Number of similar users who answered correctly
      # 2. Average success rate
      # 3. Similarity scores of users who answered

      user_count_score = (q[:similar_users_count].to_f / similar_users.size * 50).round(2)
      success_rate_score = (q[:avg_success_rate] * 30).round(2)

      cf_score = user_count_score + success_rate_score

      q.merge(cf_score: cf_score)
    end.sort_by { |q| -q[:cf_score] }
  end

  # Find similar questions based on user co-occurrence
  def find_similar_questions(base_questions, limit: 20)
    return [] if base_questions.empty?

    base_question_ids = base_questions.map { |q| q[:question_id] }

    # Find users who answered these questions correctly
    users_who_answered = TestAnswer.joins(:test_question)
                                  .where(test_questions: { question_id: base_question_ids })
                                  .where(is_correct: true)
                                  .pluck('test_sessions.user_id')
                                  .uniq

    return [] if users_who_answered.empty?

    # Find other questions these users answered correctly
    similar_question_stats = TestAnswer.joins(:test_question, test_question: :test_session)
                                      .where(test_sessions: { user_id: users_who_answered })
                                      .where.not(test_questions: { question_id: base_question_ids })
                                      .where(is_correct: true)
                                      .group('test_questions.question_id')
                                      .select(
                                        'test_questions.question_id',
                                        'COUNT(DISTINCT test_sessions.user_id) as common_users',
                                        'AVG(CASE WHEN test_answers.is_correct THEN 1.0 ELSE 0.0 END) as success_rate'
                                      )
                                      .having('common_users >= ?', [users_who_answered.size * 0.2, 2].max)

    # Filter to study set if specified
    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      similar_question_stats = similar_question_stats.joins('INNER JOIN questions ON questions.id = test_questions.question_id')
                                                    .where(questions: { study_material_id: material_ids })
    end

    # Exclude questions already answered by current user
    answered_question_ids = user.test_answers.joins(:test_question)
                               .pluck('test_questions.question_id').uniq
    similar_question_stats = similar_question_stats.where.not('test_questions.question_id': answered_question_ids)

    similar_question_stats.limit(limit).map do |stat|
      {
        question_id: stat.question_id,
        common_users: stat.common_users,
        success_rate: stat.success_rate,
        total_base_users: users_who_answered.size
      }
    end
  end

  # Score items by similarity to user's answered questions
  def score_items_by_similarity(similar_questions, base_questions)
    similar_questions.map do |q|
      # Calculate item-based CF score
      overlap_score = (q[:common_users].to_f / q[:total_base_users] * 50).round(2)
      success_score = (q[:success_rate] * 30).round(2)

      cf_score = overlap_score + success_score
      confidence = calculate_item_confidence(q[:common_users], q[:total_base_users])

      q.merge(
        cf_score: cf_score,
        confidence: confidence,
        similarity_score: overlap_score,
        based_on_questions: base_questions.map { |bq| bq[:question_id] }
      )
    end.sort_by { |q| -q[:cf_score] }
  end

  # Get questions user answered correctly
  def get_user_correct_questions
    answers = user.test_answers.joins(:test_question)
                 .where(is_correct: true)
                 .select('test_questions.question_id, test_answers.created_at')
                 .order('test_answers.created_at DESC')
                 .limit(50)

    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      answers = answers.joins('INNER JOIN questions ON questions.id = test_questions.question_id')
                      .where(questions: { study_material_id: material_ids })
    end

    answers.map { |a| { question_id: a.question_id } }
  end

  private

  # Calculate cosine similarity between two users
  def calculate_cosine_similarity(vec1, vec2)
    common_keys = vec1.keys & vec2.keys
    return 0.0 if common_keys.empty?

    dot_product = common_keys.sum { |k| vec1[k] * vec2[k] }
    magnitude1 = Math.sqrt(vec1.values.sum { |v| v**2 })
    magnitude2 = Math.sqrt(vec2.values.sum { |v| v**2 })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    (dot_product / (magnitude1 * magnitude2) * 100).round(2)
  end

  # Calculate confidence based on number of similar users
  def calculate_confidence(similar_users_count, total_similar_users)
    return 0.0 if total_similar_users.zero?

    ratio = similar_users_count.to_f / total_similar_users

    case ratio
    when 0.5..1.0 then 0.9
    when 0.3..0.5 then 0.7
    when 0.1..0.3 then 0.5
    else 0.3
    end
  end

  # Calculate confidence for item-based CF
  def calculate_item_confidence(common_users, total_users)
    return 0.0 if total_users.zero?

    ratio = common_users.to_f / total_users

    case ratio
    when 0.4..1.0 then 0.9
    when 0.2..0.4 then 0.7
    when 0.1..0.2 then 0.5
    else 0.3
    end
  end

  # Calculate confidence for hybrid CF
  def calculate_hybrid_confidence(user_score, item_score)
    # If both scores are present, confidence is higher
    if user_score > 0 && item_score > 0
      0.9
    elsif user_score > 0 || item_score > 0
      0.7
    else
      0.5
    end
  end
end
