class RecommendationService
  # 학습 추천 엔진
  # - 개인화된 문제 추천
  # - 난이도 조절 알고리즘
  # - 약점 중심 학습 큐레이션
  # - 효율적 학습 순서 최적화

  def initialize
    @openai_client = OpenaiClient.new
  end

  # 주요 메서드: 종합 추천 생성
  # @param user [User]
  # @param study_set [StudySet]
  # @param analysis_result [AnalysisResult]
  # @return [LearningRecommendation]
  def generate_comprehensive_recommendation(user, study_set, analysis_result)
    # 1. 사용자 학습 상태 분석
    user_profile = analyze_user_profile(user, study_set)

    # 2. 약점 분석
    weakness_analysis = analyze_weaknesses(user, analysis_result)

    # 3. 추천 유형 결정
    recommendation_type = determine_recommendation_type(user_profile, weakness_analysis)

    # 4. 추천 문제 선정
    recommended_questions = select_questions(
      user, study_set, weakness_analysis, user_profile, recommendation_type
    )

    # 5. 난이도 조정
    difficulty_adjusted = adjust_difficulty(user_profile, recommended_questions)

    # 6. 학습 경로 생성
    learning_path = create_learning_path(recommended_questions, weakness_analysis, user_profile)

    # 7. 효율성 계산
    efficiency_metrics = calculate_efficiency_metrics(
      user_profile, weakness_analysis, recommended_questions
    )

    # 8. 추천 저장
    recommendation = LearningRecommendation.create!(
      user_id: user.id,
      study_set_id: study_set.id,
      analysis_result_id: analysis_result.id,
      recommendation_type: recommendation_type,
      status: 'pending',
      recommended_questions: recommended_questions.map do |q|
        {
          question_id: q.id,
          priority: q[:priority],
          reason: q[:reason]
        }
      end,
      total_recommended_count: recommended_questions.count,
      suggested_difficulty: calculate_suggested_difficulty(recommended_questions),
      weakness_analysis: weakness_analysis,
      learning_path: learning_path,
      personalization_params: user_profile[:personalization],
      adaptive_params: calculate_adaptive_params(user_profile),
      learning_efficiency_index: efficiency_metrics[:efficiency],
      success_probability: efficiency_metrics[:success_probability],
      time_efficiency: efficiency_metrics[:time_efficiency],
      estimated_learning_hours: estimate_total_time(recommended_questions, learning_path),
      priority_level: determine_priority_level(weakness_analysis)
    )

    recommendation
  end

  # 개인화된 문제 추천
  # @param user [User]
  # @param study_set [StudySet]
  # @param count [Integer] 추천 개수
  # @return [Array<Question>] 추천 문제 목록
  def recommend_questions(user, study_set, count = 10)
    # 1. 사용자 학습 이력 분석
    user_stats = analyze_user_stats(user, study_set)

    # 2. 약점 감지
    weak_topics = detect_weak_topics(user, study_set)

    # 3. 학습 속도 파악
    learning_velocity = calculate_learning_velocity(user)

    # 4. 난이도 계산
    optimal_difficulty = calculate_optimal_difficulty(user_stats, learning_velocity)

    # 5. 문제 풀이 이력 제외
    solved_question_ids = user.exam_answers.pluck(:question_id).uniq

    # 6. 문제 선정
    questions = Question.where(study_material_id: study_set.study_materials.pluck(:id))
                        .where.not(id: solved_question_ids)
                        .by_difficulty(optimal_difficulty)
                        .by_topic(weak_topics.first)
                        .limit(count)

    questions.map do |q|
      {
        id: q.id,
        content: q.content,
        difficulty: q.difficulty,
        topic: q.topic,
        score: calculate_question_score(q, user, weak_topics)
      }
    end.sort_by { |q| q[:score] }.reverse
  end

  # 난이도 적응형 조정
  # @param user [User]
  # @param study_set [StudySet]
  # @return [Float] 추천 난이도 (1-5)
  def adaptive_difficulty_adjustment(user, study_set)
    recent_performance = get_recent_performance(user, 10)
    accuracy = recent_performance[:accuracy]

    case accuracy
    when 0.8..1.0
      # 높은 정답률 -> 난이도 상향
      [[recent_performance[:current_difficulty] + 1, 5].min, 1].max
    when 0.6..0.8
      # 중간 정답률 -> 현재 난이도 유지
      recent_performance[:current_difficulty]
    when 0.4..0.6
      # 낮은 정답률 -> 난이도 하향
      [[recent_performance[:current_difficulty] - 1, 1].max, 5].min
    else
      # 매우 낮은 정답률 -> 크게 하향
      [1, recent_performance[:current_difficulty] - 2].max
    end
  end

  # 약점 중심 학습 큐레이션
  # @param user [User]
  # @param study_set [StudySet]
  # @return [Hash] 약점 기반 추천
  def weakness_focused_curation(user, study_set)
    # 1. 약점 개념 파악
    weak_concepts = identify_weak_concepts(user, study_set)
    return {} if weak_concepts.empty?

    # 2. 각 약점별 문제 선정
    curated_by_weakness = {}
    weak_concepts.each do |concept|
      questions = find_questions_for_concept(concept, study_set, user)
      curated_by_weakness[concept] = questions.take(5)
    end

    # 3. 우선순위 지정
    {
      weak_concepts: weak_concepts.map { |c| { name: c, priority: 1 } },
      curated_questions: curated_by_weakness,
      total_questions: curated_by_weakness.values.sum(&:count),
      estimated_time: estimate_curation_time(curated_by_weakness)
    }
  end

  # 효율적 학습 순서 최적화
  # @param questions [Array<Question>]
  # @param user_profile [Hash]
  # @return [Array<Question>] 최적화된 순서
  def optimize_learning_order(questions, user_profile)
    # 1. 선행 개념 의존성 분석
    dependency_graph = build_dependency_graph(questions)

    # 2. 토폴로지 정렬 (위상 정렬)
    sorted_order = topological_sort(dependency_graph)

    # 3. 학습 속도에 맞춘 재배열
    reordered = adjust_order_by_pace(sorted_order, user_profile[:learning_pace])

    reordered
  end

  # ============ 헬퍼 메서드 ============

  private

  def analyze_user_profile(user, study_set)
    stats = analyze_user_stats(user, study_set)
    velocity = calculate_learning_velocity(user)

    {
      learning_pace: determine_learning_pace(velocity),
      concentration_level: estimate_concentration(user),
      learning_style: infer_learning_style(user),
      optimal_session_length: calculate_optimal_session_length(user),
      preferred_difficulty: calculate_preferred_difficulty(stats),
      personalization: {
        learning_style: infer_learning_style(user),
        pace: determine_learning_pace(velocity),
        concentration_level: estimate_concentration(user)
      }
    }
  end

  def analyze_weaknesses(user, analysis_result)
    prerequisites = analysis_result.prerequisites
    related_concepts = analysis_result.related_concepts

    {
      concept_gaps: prerequisites.map do |p|
        mastery = user.user_masteries.find_by(knowledge_node_id: p[:concept_id])
        {
          concept_id: p[:concept_id],
          concept_name: p[:name],
          gap_score: 1.0 - (mastery&.mastery_level || 0.0),
          mastery_level: mastery&.mastery_level || 0.0,
          priority: p[:relevance_score]
        }
      end,
      error_patterns: analysis_result.llm_analysis_metadata&.fetch('error_patterns', []) || [],
      mastery_predictions: analysis_result.llm_analysis_metadata&.fetch('mastery_predictions', []) || []
    }
  end

  def determine_recommendation_type(user_profile, weakness_analysis)
    gap_count = weakness_analysis[:concept_gaps].count
    avg_gap = weakness_analysis[:concept_gaps].average { |g| g[:gap_score] }

    case gap_count
    when 0..2
      avg_gap > 0.5 ? 'remedial' : 'progressive'
    when 3..5
      'progressive'
    else
      'comprehensive'
    end
  end

  def select_questions(user, study_set, weakness_analysis, user_profile, recommendation_type)
    weak_topics = weakness_analysis[:concept_gaps].map { |g| g[:concept_name] }
    solved_ids = user.exam_answers.pluck(:question_id).uniq

    questions = Question.where(study_material_id: study_set.study_materials.pluck(:id))
                        .where.not(id: solved_ids)

    case recommendation_type
    when 'remedial'
      # 약점 집중 공략
      questions.where(topic: weak_topics).by_difficulty(2).random.limit(10)
    when 'progressive'
      # 단계적 학습
      weak_diff = calculate_suggested_difficulty(questions.where(topic: weak_topics))
      questions.where(topic: weak_topics).by_difficulty(weak_diff).random.limit(8)
    else
      # 종합 학습
      questions.random.limit(15)
    end.map do |q|
      {
        id: q.id,
        question: q,
        priority: calculate_question_priority(q, weak_topics),
        reason: generate_selection_reason(q, weak_topics)
      }
    end
  end

  def adjust_difficulty(user_profile, recommended_questions)
    base_difficulty = recommended_questions.average { |q| q[:question].difficulty }
    adjustment = calculate_difficulty_adjustment(user_profile)

    {
      base_difficulty: base_difficulty,
      adjustment_ratio: adjustment,
      final_difficulty: [base_difficulty * adjustment, 5].min.round
    }
  end

  def create_learning_path(recommended_questions, weakness_analysis, user_profile)
    steps = []
    weak_concepts = weakness_analysis[:concept_gaps].sort_by { |g| g[:priority] }.reverse

    weak_concepts.each_with_index do |concept, index|
      # 해당 개념과 관련된 문제만 필터링
      concept_questions = recommended_questions.select do |rq|
        rq[:question].topic == concept[:concept_name]
      end

      steps << {
        step_number: index + 1,
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        focus_duration: estimate_focus_duration(concept[:gap_score]),
        questions: concept_questions.map { |q| q[:id] },
        prerequisite_concepts: [],
        success_criteria: {
          accuracy_target: 0.8,
          repetition_target: 2
        }
      }
    end

    steps
  end

  def calculate_efficiency_metrics(user_profile, weakness_analysis, recommended_questions)
    # 학습 효율성 지수 계산
    efficiency = calculate_learning_efficiency(user_profile, weakness_analysis)

    # 성공 확률 예측
    success_probability = predict_success(user_profile, weakness_analysis)

    # 시간 효율성
    time_efficiency = estimate_time_efficiency(user_profile, recommended_questions)

    {
      efficiency: efficiency,
      success_probability: success_probability,
      time_efficiency: time_efficiency
    }
  end

  def analyze_user_stats(user, study_set)
    answers = user.exam_answers.joins(:question)
                   .where(questions: { study_material_id: study_set.study_materials.pluck(:id) })

    {
      total_attempts: answers.count,
      correct_answers: answers.where(is_correct: true).count,
      accuracy: answers.where(is_correct: true).count.to_f / (answers.count + 1),
      current_difficulty: answers.average(:time_spent) || 3,
      recent_streak: calculate_streak(user)
    }
  end

  def detect_weak_topics(user, study_set)
    answers = user.exam_answers.joins(:question)
                   .where(questions: { study_material_id: study_set.study_materials.pluck(:id) })
                   .select('questions.topic, COUNT(*) as attempt_count, SUM(CASE WHEN exam_answers.is_correct THEN 1 ELSE 0 END) as correct_count')
                   .group('questions.topic')

    topics_with_accuracy = answers.map do |record|
      accuracy = record.correct_count.to_f / record.attempt_count
      [record.topic, accuracy]
    end

    topics_with_accuracy.sort_by { |_, acc| acc }.take(5).map(&:first)
  end

  def calculate_learning_velocity(user)
    recent_answers = user.exam_answers.recent.limit(20)
    return 0.0 if recent_answers.count < 5

    accuracy_trend = recent_answers.map { |a| a.is_correct ? 1 : 0 }
    improvement = accuracy_trend.last(5).sum.to_f / 5 - accuracy_trend.first(5).sum.to_f / 5

    improvement > 0 ? 'ascending' : 'descending'
  end

  def calculate_optimal_difficulty(user_stats, learning_velocity)
    base_difficulty = user_stats[:current_difficulty]

    case learning_velocity
    when 'ascending'
      [base_difficulty + 1, 5].min
    when 'descending'
      [base_difficulty - 1, 1].max
    else
      base_difficulty
    end
  end

  def calculate_question_score(question, user, weak_topics)
    # 문제 선정 점수 계산
    relevance_score = weak_topics.include?(question.topic) ? 1.0 : 0.5
    difficulty_score = 1.0 - (question.difficulty - 3).abs / 5.0
    novelty_score = user.exam_answers.where(question_id: question.id).exists? ? 0 : 1.0

    (relevance_score * 0.5 + difficulty_score * 0.3 + novelty_score * 0.2).round(3)
  end

  def determine_learning_pace(velocity)
    velocity == 'ascending' ? 'fast' : 'normal'
  end

  def estimate_concentration(user)
    recent_sessions = user.exam_sessions.recent.limit(5)
    avg_duration = recent_sessions.average(:time_limit) || 60

    case avg_duration
    when 0...30
      'low'
    when 30...60
      'medium'
    else
      'high'
    end
  end

  def infer_learning_style(user)
    # 학습 스타일 추론 (시각, 청각, 운동감각 등)
    'balanced' # MVP에서는 기본값
  end

  def calculate_optimal_session_length(user)
    # 사용자 집중력 기반 추천 세션 시간
    30 # MVP에서는 기본값
  end

  def calculate_preferred_difficulty(stats)
    stats[:current_difficulty].round
  end

  def get_recent_performance(user, count = 10)
    recent = user.exam_answers.recent.limit(count)
    correct = recent.where(is_correct: true).count
    accuracy = correct.to_f / (recent.count + 1)

    {
      accuracy: accuracy,
      current_difficulty: recent.average(:time_spent) || 3
    }
  end

  def identify_weak_concepts(user, study_set)
    user.user_masteries.joins(:knowledge_node)
        .where(knowledge_nodes: { study_material_id: study_set.study_materials.pluck(:id) })
        .where('user_masteries.mastery_level < ?', 0.7)
        .pluck('knowledge_nodes.name')
        .uniq
  end

  def find_questions_for_concept(concept, study_set, user)
    solved_ids = user.exam_answers.pluck(:question_id).uniq

    Question.where(study_material_id: study_set.study_materials.pluck(:id))
            .where(topic: concept)
            .where.not(id: solved_ids)
            .random
  end

  def estimate_curation_time(curated)
    curated.values.sum { |qs| qs.count * 5 } / 60.0
  end

  def build_dependency_graph(questions)
    # 선행 개념 의존성 그래프 구축
    {} # MVP에서는 단순화
  end

  def topological_sort(dependency_graph)
    # 위상 정렬
    [] # MVP에서는 단순화
  end

  def adjust_order_by_pace(sorted_order, pace)
    # 학습 속도에 맞춘 재배열
    sorted_order
  end

  def calculate_difficulty_adjustment(user_profile)
    case user_profile[:learning_pace]
    when 'fast'
      1.2
    when 'slow'
      0.8
    else
      1.0
    end
  end

  def calculate_suggested_difficulty(questions)
    questions.average(:difficulty).round
  end

  def calculate_question_priority(question, weak_topics)
    weak_topics.include?(question.topic) ? 10 : 5
  end

  def generate_selection_reason(question, weak_topics)
    if weak_topics.include?(question.topic)
      "약점 개념(#{question.topic}) 공략"
    else
      "기초 강화"
    end
  end

  def estimate_focus_duration(gap_score)
    case gap_score
    when 0.7..1.0
      30
    when 0.4..0.7
      20
    else
      10
    end
  end

  def calculate_learning_efficiency(user_profile, weakness_analysis)
    gaps = weakness_analysis[:concept_gaps]
    return 0.0 if gaps.empty?

    avg_gap = gaps.average { |g| g[:gap_score] }
    learning_capacity = case user_profile[:learning_pace]
                        when 'fast'
                          0.9
                        when 'slow'
                          0.6
                        else
                          0.75
                        end

    (learning_capacity * (1.0 - avg_gap)).round(3)
  end

  def predict_success(user_profile, weakness_analysis)
    # 성공 확률 예측
    0.65 # MVP 기본값
  end

  def estimate_time_efficiency(user_profile, recommended_questions)
    # 시간 효율성 계산
    1.0 # MVP 기본값
  end

  def calculate_adaptive_params(user_profile)
    {
      adjustment_frequency: 'after_each_session',
      difficulty_step_size: 0.5,
      learning_pace_adjustment: user_profile[:learning_pace]
    }
  end

  def estimate_total_time(recommended_questions, learning_path)
    # 총 학습 시간 추정
    (recommended_questions.count * 5 + learning_path.sum { |s| s[:focus_duration] || 0 }) / 60.0
  end

  def determine_priority_level(weakness_analysis)
    gaps = weakness_analysis[:concept_gaps]
    critical_gaps = gaps.count { |g| g[:gap_score] > 0.7 }

    case critical_gaps
    when 0
      5
    when 1..2
      7
    else
      10
    end
  end

  def calculate_streak(user)
    # 최근 연속 정답 스트릭 계산
    recent = user.exam_answers.recent.limit(10)
    recent.where(is_correct: true).count
  end
end
