# app/services/recommendation_engine.rb
class RecommendationEngine
  attr_reader :user, :study_set, :explanation

  def initialize(user, study_set = nil)
    @user = user
    @study_set = study_set
    @explanation = {}
  end

  # Generate comprehensive recommendations
  def generate_recommendations(force: false)
    return [] unless study_set

    # Check if recent recommendations exist
    if !force && recent_recommendations_exist?
      return user.learning_recommendations
                 .where(study_set: study_set, status: 'pending')
                 .order(priority_level: :desc)
    end

    recommendations = []

    # 1. Weakness-based recommendations
    recommendations.concat(weakness_based_recommendations)

    # 2. Collaborative filtering recommendations
    recommendations.concat(collaborative_recommendations)

    # 3. Content-based recommendations
    recommendations.concat(content_based_recommendations)

    # 4. Sequential learning recommendations
    recommendations.concat(sequential_recommendations)

    recommendations
  end

  # Generate personalized learning path
  def generate_learning_path
    return { error: 'No study set provided' } unless study_set

    # Get user's current mastery state
    masteries = user.user_masteries
                   .joins(:knowledge_node)
                   .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })

    weak_concepts = masteries.where(status: 'weak').order(mastery_level: :asc)
    untested_concepts = masteries.where(status: 'untested')

    path = {
      current_level: calculate_current_level(masteries),
      phases: []
    }

    # Phase 1: Fix critical weaknesses
    if weak_concepts.any?
      path[:phases] << {
        phase: 1,
        name: '약점 개념 보강',
        description: '가장 약한 개념부터 집중 학습',
        concepts: weak_concepts.limit(5).map { |m| format_concept(m) },
        estimated_hours: weak_concepts.count * 0.5,
        priority: 'high'
      }
    end

    # Phase 2: Learn untested concepts with prerequisites
    if untested_concepts.any?
      ordered_concepts = order_by_prerequisites(untested_concepts)
      path[:phases] << {
        phase: 2,
        name: '신규 개념 학습',
        description: '선수 지식부터 순차적으로 학습',
        concepts: ordered_concepts.take(10).map { |m| format_concept(m) },
        estimated_hours: ordered_concepts.count * 0.3,
        priority: 'medium'
      }
    end

    # Phase 3: Reinforce learning concepts
    learning_concepts = masteries.where(status: 'learning').order(mastery_level: :asc)
    if learning_concepts.any?
      path[:phases] << {
        phase: 3,
        name: '학습 중인 개념 강화',
        description: '이해도를 높여 숙달 단계로 진입',
        concepts: learning_concepts.limit(5).map { |m| format_concept(m) },
        estimated_hours: learning_concepts.count * 0.2,
        priority: 'low'
      }
    end

    # Phase 4: Advanced practice
    mastered_concepts = masteries.where(status: 'mastered')
    if mastered_concepts.count > 10
      path[:phases] << {
        phase: 4,
        name: '종합 문제 풀이',
        description: '여러 개념을 통합하는 고난도 문제',
        concepts: ['통합 문제', '실전 모의고사'],
        estimated_hours: 2,
        priority: 'optional'
      }
    end

    path[:total_estimated_hours] = path[:phases].sum { |p| p[:estimated_hours] }
    path
  end

  # Personalized recommendations based on multiple factors
  def personalized_recommendations(limit: 10)
    return [] unless study_set

    scores = {}

    # Factor 1: Recent errors (40% weight)
    recent_errors = recent_error_questions
    recent_errors.each do |question_id|
      scores[question_id] ||= 0
      scores[question_id] += 40
    end

    # Factor 2: Weak concept questions (30% weight)
    weak_concept_questions = questions_for_weak_concepts
    weak_concept_questions.each do |question_id|
      scores[question_id] ||= 0
      scores[question_id] += 30
    end

    # Factor 3: Similar user preferences (20% weight)
    similar_user_questions = questions_from_similar_users
    similar_user_questions.each do |question_id|
      scores[question_id] ||= 0
      scores[question_id] += 20
    end

    # Factor 4: Spaced repetition (10% weight)
    spaced_repetition_questions = questions_needing_review
    spaced_repetition_questions.each do |question_id|
      scores[question_id] ||= 0
      scores[question_id] += 10
    end

    # Sort by score and get top recommendations
    top_question_ids = scores.sort_by { |_, score| -score }.take(limit).map(&:first)

    questions = Question.where(id: top_question_ids, study_material_id: study_set.study_materials.pluck(:id))

    @explanation = {
      recent_errors_count: recent_errors.count,
      weak_concepts_count: weak_concept_questions.count,
      similar_users_influence: similar_user_questions.count,
      spaced_repetition_count: spaced_repetition_questions.count,
      scoring_weights: {
        recent_errors: '40%',
        weak_concepts: '30%',
        similar_users: '20%',
        spaced_repetition: '10%'
      }
    }

    questions.map { |q| format_question_recommendation(q, scores[q.id]) }
  end

  # Find similar users based on learning patterns
  def find_similar_users(limit: 10)
    # Find users with similar test performance patterns
    user_masteries = user.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h

    similar_users = User.joins(:user_masteries)
                       .where.not(id: user.id)
                       .group('users.id')
                       .having('COUNT(user_masteries.id) >= ?', [user_masteries.size * 0.3, 5].max)
                       .limit(limit * 3) # Get more for filtering

    similarity_scores = similar_users.map do |other_user|
      other_masteries = other_user.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h
      similarity = calculate_cosine_similarity(user_masteries, other_masteries)

      {
        user_id: other_user.id,
        user_name: other_user.name || other_user.email.split('@').first,
        similarity_score: similarity,
        common_concepts: (user_masteries.keys & other_masteries.keys).size
      }
    end

    similarity_scores.sort_by { |s| -s[:similarity_score] }.take(limit)
  end

  # Get trending items across platform
  def self.global_trending(limit: 10)
    # Find most practiced questions in last 7 days
    TestAnswer.joins(:test_question)
             .where('test_answers.created_at >= ?', 7.days.ago)
             .group('test_questions.question_id')
             .order('COUNT(*) DESC')
             .limit(limit)
             .pluck('test_questions.question_id', Arel.sql('COUNT(*)'))
             .map { |q_id, count| { question_id: q_id, practice_count: count } }
  end

  # Get trending in specific study set
  def self.trending_in_study_set(study_set_id, limit: 10)
    study_set = StudySet.find(study_set_id)
    material_ids = study_set.study_materials.pluck(:id)

    Question.joins(test_questions: :test_answers)
           .where(study_material_id: material_ids)
           .where('test_answers.created_at >= ?', 7.days.ago)
           .group('questions.id')
           .order('COUNT(*) DESC')
           .limit(limit)
           .pluck('questions.id', Arel.sql('COUNT(*)'))
           .map { |q_id, count| { question_id: q_id, practice_count: count } }
  end

  # Suggest next steps based on current progress
  def suggest_next_steps
    return {} unless study_set

    masteries = user.user_masteries
                   .joins(:knowledge_node)
                   .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })

    total = masteries.count
    mastered = masteries.where(status: 'mastered').count
    progress_percentage = total.zero? ? 0 : (mastered.to_f / total * 100).round(2)

    suggestions = []

    if progress_percentage < 25
      suggestions << {
        action: 'focus_on_fundamentals',
        title: '기초 개념 집중 학습',
        description: '선수 지식부터 차근차근 학습하세요',
        priority: 'high'
      }
    elsif progress_percentage < 50
      suggestions << {
        action: 'practice_weak_areas',
        title: '약점 보완',
        description: '틀린 문제와 약한 개념을 중점적으로 연습하세요',
        priority: 'high'
      }
    elsif progress_percentage < 75
      suggestions << {
        action: 'comprehensive_review',
        title: '종합 복습',
        description: '배운 내용을 통합하는 연습을 하세요',
        priority: 'medium'
      }
    else
      suggestions << {
        action: 'advanced_practice',
        title: '실전 연습',
        description: '모의고사와 고난도 문제로 실력을 다지세요',
        priority: 'medium'
      }
    end

    # Check recent activity
    recent_sessions = user.test_sessions
                         .where(study_set: study_set)
                         .where('created_at >= ?', 7.days.ago)

    if recent_sessions.empty?
      suggestions << {
        action: 'resume_study',
        title: '학습 재개',
        description: '일주일 동안 학습하지 않으셨어요. 다시 시작해보세요!',
        priority: 'urgent'
      }
    end

    {
      current_progress: progress_percentage,
      study_streak: calculate_study_streak,
      suggestions: suggestions.sort_by { |s| suggestion_priority_value(s[:priority]) }
    }
  end

  def recommendation_explanation
    @explanation
  end

  private

  def recent_recommendations_exist?
    user.learning_recommendations
        .where(study_set: study_set, status: 'pending')
        .where('created_at >= ?', 1.day.ago)
        .exists?
  end

  # Weakness-based recommendations
  def weakness_based_recommendations
    weak_masteries = user.user_masteries
                        .joins(:knowledge_node)
                        .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })
                        .where(status: 'weak')
                        .order(mastery_level: :asc)
                        .limit(3)

    weak_masteries.map do |mastery|
      questions = Question.where(study_material_id: study_set.study_materials.pluck(:id))
                         .limit(5)

      create_recommendation(
        recommendation_type: 'weakness_based',
        priority_level: 9,
        recommended_questions: questions.pluck(:id),
        weakness_analysis: {
          weak_concept: mastery.knowledge_node.name,
          mastery_level: mastery.mastery_level,
          attempts: mastery.attempts
        }
      )
    end.compact
  end

  # Collaborative filtering recommendations
  def collaborative_recommendations
    similar_users = find_similar_users(limit: 5)
    return [] if similar_users.empty?

    similar_user_ids = similar_users.map { |u| u[:user_id] }

    # Find questions that similar users practiced and did well on
    successful_questions = TestAnswer.joins(:test_question)
                                    .where(test_questions: { test_session: { user_id: similar_user_ids } })
                                    .where(is_correct: true)
                                    .group('test_questions.question_id')
                                    .having('COUNT(*) >= ?', similar_users.count * 0.5)
                                    .pluck('test_questions.question_id')

    # Filter to current study set
    study_questions = Question.where(
      id: successful_questions,
      study_material_id: study_set.study_materials.pluck(:id)
    ).limit(10)

    return [] if study_questions.empty?

    [create_recommendation(
      recommendation_type: 'collaborative',
      priority_level: 6,
      recommended_questions: study_questions.pluck(:id),
      personalization_params: {
        similar_users_count: similar_users.count,
        avg_similarity: similar_users.map { |u| u[:similarity_score] }.sum / similar_users.count
      }
    )].compact
  end

  # Content-based recommendations
  def content_based_recommendations
    # Find concepts user is currently learning
    learning_masteries = user.user_masteries
                            .joins(:knowledge_node)
                            .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })
                            .where(status: 'learning')
                            .limit(3)

    learning_masteries.map do |mastery|
      # Find related concepts
      related_nodes = KnowledgeEdge.where(knowledge_node_id: mastery.knowledge_node_id)
                                  .where(relationship_type: ['prerequisite', 'related'])
                                  .pluck(:related_node_id)

      questions = Question.where(study_material_id: study_set.study_materials.pluck(:id))
                         .limit(5)

      create_recommendation(
        recommendation_type: 'content_based',
        priority_level: 7,
        recommended_questions: questions.pluck(:id),
        concept_mastery_map: {
          focus_concept: mastery.knowledge_node.name,
          related_concepts: related_nodes.count
        }
      )
    end.compact
  end

  # Sequential learning recommendations
  def sequential_recommendations
    # Find next logical concepts to learn based on prerequisites
    mastered_nodes = user.user_masteries
                        .joins(:knowledge_node)
                        .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })
                        .where(status: 'mastered')
                        .pluck(:knowledge_node_id)

    # Find concepts that have prerequisites met
    next_concepts = KnowledgeNode.where(study_material_id: study_set.study_materials.pluck(:id))
                                 .where.not(id: mastered_nodes)
                                 .select do |node|
                                   prerequisites = KnowledgeEdge.where(
                                     related_node_id: node.id,
                                     relationship_type: 'prerequisite'
                                   ).pluck(:knowledge_node_id)

                                   prerequisites.empty? || (prerequisites - mastered_nodes).empty?
                                 end

    return [] if next_concepts.empty?

    [create_recommendation(
      recommendation_type: 'sequential',
      priority_level: 8,
      recommended_questions: [],
      learning_path: next_concepts.take(5).map(&:name)
    )].compact
  end

  def create_recommendation(attrs)
    LearningRecommendation.create!(
      user: user,
      study_set: study_set,
      **attrs
    )
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create recommendation: #{e.message}"
    nil
  end

  def calculate_current_level(masteries)
    return 'beginner' if masteries.empty?

    mastered_percentage = (masteries.where(status: 'mastered').count.to_f / masteries.count * 100)

    case mastered_percentage
    when 0...25 then 'beginner'
    when 25...50 then 'intermediate'
    when 50...75 then 'advanced'
    else 'expert'
    end
  end

  def order_by_prerequisites(masteries)
    # Simple topological sort based on prerequisites
    # In a real implementation, this would be more sophisticated
    masteries.to_a.sort_by do |mastery|
      prerequisites = KnowledgeEdge.where(
        related_node_id: mastery.knowledge_node_id,
        relationship_type: 'prerequisite'
      ).count
      prerequisites
    end
  end

  def format_concept(mastery)
    {
      id: mastery.knowledge_node.id,
      name: mastery.knowledge_node.name,
      mastery_level: mastery.mastery_level,
      status: mastery.status,
      attempts: mastery.attempts
    }
  end

  def format_question_recommendation(question, score)
    {
      question_id: question.id,
      question_number: question.question_number,
      content_preview: question.question_text&.truncate(100),
      recommendation_score: score,
      difficulty: estimate_difficulty(question)
    }
  end

  def estimate_difficulty(question)
    # Estimate based on how many users answered correctly
    answers = TestAnswer.joins(:test_question).where(test_questions: { question_id: question.id })
    return 'medium' if answers.empty?

    correct_rate = answers.where(is_correct: true).count.to_f / answers.count
    case correct_rate
    when 0...0.3 then 'hard'
    when 0.3...0.7 then 'medium'
    else 'easy'
    end
  end

  def recent_error_questions
    TestAnswer.joins(:test_question)
              .where(test_questions: { test_session: { user_id: user.id, study_set_id: study_set.id } })
              .where(is_correct: false)
              .where('test_answers.created_at >= ?', 30.days.ago)
              .pluck('test_questions.question_id')
              .uniq
  end

  def questions_for_weak_concepts
    weak_nodes = user.user_masteries
                    .joins(:knowledge_node)
                    .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })
                    .where(status: 'weak')
                    .pluck(:knowledge_node_id)

    return [] if weak_nodes.empty?

    Question.where(study_material_id: study_set.study_materials.pluck(:id)).pluck(:id)
  end

  def questions_from_similar_users
    similar_users = find_similar_users(limit: 5)
    return [] if similar_users.empty?

    TestAnswer.joins(:test_question)
              .where(test_questions: { test_session: { user_id: similar_users.map { |u| u[:user_id] } } })
              .where(is_correct: true)
              .where('test_answers.created_at >= ?', 30.days.ago)
              .group('test_questions.question_id')
              .having('COUNT(*) >= ?', 2)
              .pluck('test_questions.question_id')
  end

  def questions_needing_review
    # Questions answered correctly more than 7 days ago
    TestAnswer.joins(:test_question)
              .where(test_questions: { test_session: { user_id: user.id, study_set_id: study_set.id } })
              .where(is_correct: true)
              .where('test_answers.created_at <= ?', 7.days.ago)
              .pluck('test_questions.question_id')
              .uniq
  end

  def calculate_cosine_similarity(vec1, vec2)
    common_keys = vec1.keys & vec2.keys
    return 0.0 if common_keys.empty?

    dot_product = common_keys.sum { |k| vec1[k] * vec2[k] }
    magnitude1 = Math.sqrt(vec1.values.sum { |v| v**2 })
    magnitude2 = Math.sqrt(vec2.values.sum { |v| v**2 })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    (dot_product / (magnitude1 * magnitude2) * 100).round(2)
  end

  def calculate_study_streak
    dates = user.test_sessions.where(status: 'completed')
               .order(created_at: :desc)
               .pluck(:created_at)
               .map { |d| d.to_date }
               .uniq

    return 0 if dates.empty?

    streak = 1
    dates.each_cons(2) do |current, previous|
      break unless (previous - current).to_i == 1
      streak += 1
    end
    streak
  end

  def suggestion_priority_value(priority)
    { 'urgent' => 1, 'high' => 2, 'medium' => 3, 'low' => 4, 'optional' => 5 }[priority] || 10
  end
end
