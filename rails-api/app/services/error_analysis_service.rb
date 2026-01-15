class ErrorAnalysisService
  # 오답 분석 서비스
  # - 오답 원인 상세 분석 (부주의 vs 개념 부족)
  # - 오답 패턴 인식
  # - 개념 연결성 분석
  # - 추천 학습 경로 생성

  def initialize
    @openai_client = OpenaiClient.new
  end

  # 오답 원인 상세 분석
  # @param user [User]
  # @param question [Question]
  # @param selected_answer [String]
  # @param analysis_result [AnalysisResult] GraphRAG 분석 결과
  # @return [Hash] 상세 분석 결과
  def analyze_error_in_depth(user, question, selected_answer, analysis_result)
    {
      error_classification: classify_error(user, question, selected_answer),
      conceptual_gaps: identify_conceptual_gaps(user, question, analysis_result),
      error_patterns: detect_error_patterns(user, selected_answer),
      similar_mistakes: find_similar_mistakes(user, question),
      knowledge_connections: analyze_concept_connections(question, analysis_result)
    }
  end

  # 오답 유형 분류: 부주의, 개념 부족, 혼합
  def classify_error(user, question, selected_answer)
    # GraphRAG 분석 결과 활용
    correct_answer = question.answer
    is_same_concept_question_passed = user_passed_similar_question?(user, question)

    {
      type: determine_error_type(is_same_concept_question_passed, user, question),
      severity: assess_severity(question.difficulty, user, question),
      careless_indicators: detect_careless_indicators(question, selected_answer),
      concept_gap_indicators: detect_concept_gap_indicators(user, question, selected_answer)
    }
  end

  # 개념 격차 식별
  def identify_conceptual_gaps(user, question, analysis_result)
    prerequisites = analysis_result.prerequisites
    related_mastery = user.user_masteries.where(
      knowledge_node_id: prerequisites.map { |p| p[:concept_id] }
    )

    gaps = prerequisites.map do |prereq|
      mastery = related_mastery.find { |m| m.knowledge_node_id == prereq[:concept_id] }
      {
        concept_id: prereq[:concept_id],
        concept_name: prereq[:name],
        user_mastery_level: mastery&.mastery_level || 0.0,
        expected_mastery_level: 0.8,
        gap_level: [0.8 - (mastery&.mastery_level || 0.0), 0.0].max,
        is_critical: (mastery&.mastery_level || 0.0) < 0.6
      }
    end

    gaps.sort_by { |g| g[:gap_level] }.reverse
  end

  # 오답 패턴 탐지
  def detect_error_patterns(user, selected_answer)
    wrong_answers = user.wrong_answers.recent.limit(20)

    patterns = {
      frequently_selected_wrong_options: detect_option_bias(user),
      temporal_patterns: detect_temporal_patterns(user),
      difficulty_based_errors: detect_difficulty_bias(user),
      topic_based_errors: detect_topic_bias(user),
      distractor_susceptibility: analyze_distractor_susceptibility(user)
    }

    patterns
  end

  # 유사한 오답 찾기
  def find_similar_mistakes(user, current_question)
    # 사용자의 과거 오답 중 같은 개념 관련 문제 찾기
    wrong_answer_questions = user.wrong_answers.select(:question_id).map(&:question_id)
    similar_questions = Question.where(
      topic: current_question.topic,
      id: wrong_answer_questions
    ).limit(5)

    similar_mistakes = similar_questions.map do |q|
      wrong_answer = user.wrong_answers.find_by(question_id: q.id)
      {
        question_id: q.id,
        question_content: q.content,
        user_selected: wrong_answer&.selected_answer,
        correct_answer: q.answer,
        topic: q.topic,
        difficulty: q.difficulty,
        mistake_date: wrong_answer&.last_attempted_at,
        attempt_count: wrong_answer&.attempt_count || 1
      }
    end

    similar_mistakes.sort_by { |m| m[:attempt_count] }.reverse
  end

  # 개념 연결성 분석
  def analyze_concept_connections(question, analysis_result)
    # 분석 결과에서 개념 관계 추출
    {
      direct_prerequisites: analysis_result.prerequisites.count,
      total_related_concepts: analysis_result.related_concepts&.count || 0,
      concept_hierarchy: build_concept_hierarchy(analysis_result),
      knowledge_gaps_in_chain: identify_gaps_in_prerequisite_chain(analysis_result),
      critical_junctions: find_critical_junctions(analysis_result)
    }
  end

  # 추천 학습 경로 생성
  # @param user [User]
  # @param analysis_result [AnalysisResult]
  # @param study_set [StudySet]
  # @return [Hash] 상세 학습 경로
  def generate_learning_path(user, analysis_result, study_set)
    # 1. 약점 개념 식별
    weak_concepts = identify_weak_concepts(user, analysis_result)

    # 2. 학습 경로 계획
    learning_path_steps = plan_learning_steps(weak_concepts, analysis_result, study_set, user)

    # 3. 연습 문제 선정
    practice_questions = select_practice_questions(weak_concepts, study_set, user)

    # 4. 예상 학습 시간 계산
    estimated_time = estimate_learning_time(learning_path_steps, practice_questions)

    {
      weak_concepts: weak_concepts,
      learning_path: learning_path_steps,
      practice_questions: practice_questions,
      estimated_hours: estimated_time,
      difficulty_progression: plan_difficulty_progression(weak_concepts),
      expected_improvement: estimate_improvement(weak_concepts),
      success_probability: calculate_success_probability(user, weak_concepts)
    }
  end

  # ============ 헬퍼 메서드 ============

  private

  def determine_error_type(is_same_concept_passed, user, question)
    if is_same_concept_passed
      'careless' # 같은 개념의 다른 문제는 맞혔으므로 부주의
    else
      'concept_gap' # 같은 개념 관련 문제를 틀렸으므로 개념 부족
    end
  end

  def assess_severity(difficulty, user, question)
    user_avg_difficulty = user.exam_answers.average(:time_spent) || 0
    difficulty > 3 ? 'high' : 'medium'
  end

  def detect_careless_indicators(question, selected_answer)
    indicators = []

    # 지시문 명시적 부주의 (예: "다음 중 틀린 것은?")
    if question.content.include?("틀린") && selected_answer == question.answer
      indicators << "반대 지시문 오독"
    end

    # 선택지 유사성 검토
    indicators
  end

  def detect_concept_gap_indicators(user, question, selected_answer)
    indicators = []

    # 최근 유사 개념 정답률 낮음
    if get_concept_accuracy(user, question) < 50
      indicators << "저정답률"
    end

    # 선행 개념 미숙달
    indicators << "선행개념미숙달"

    indicators
  end

  def user_passed_similar_question?(user, question)
    # 같은 주제 문제 중 정답한 것이 있는지 확인
    User::ExamAnswer
      .joins(:question)
      .where(user_id: user.id, questions: { topic: question.topic }, is_correct: true)
      .exists?
  end

  def detect_option_bias(user)
    wrong_answers = user.wrong_answers.recent.limit(30)
    selected_options = wrong_answers.pluck(:selected_answer)

    option_frequency = selected_options.each_with_object({}) do |option, hash|
      hash[option] ||= 0
      hash[option] += 1
    end

    option_frequency.sort_by { |_, count| count }.reverse.take(3)
  end

  def detect_temporal_patterns(user)
    wrong_answers = user.wrong_answers.recent.limit(50)

    by_hour = wrong_answers.group_by { |wa| wa.last_attempted_at.hour }
    most_errors_hour = by_hour.max_by { |_, v| v.count }&.first

    {
      most_errors_hour: most_errors_hour,
      pattern_detected: most_errors_hour.present?
    }
  end

  def detect_difficulty_bias(user)
    wrong_answers = user.wrong_answers.joins(:question).recent.limit(50)

    by_difficulty = wrong_answers.group_by { |wa| wa.question.difficulty }
    most_errors_difficulty = by_difficulty.max_by { |_, v| v.count }&.first

    {
      problem_difficulty: most_errors_difficulty,
      count: by_difficulty[most_errors_difficulty]&.count || 0
    }
  end

  def detect_topic_bias(user)
    wrong_answers = user.wrong_answers.joins(:question).recent.limit(50)

    by_topic = wrong_answers.group_by { |wa| wa.question.topic }
    most_errors_topic = by_topic.max_by { |_, v| v.count }&.first

    {
      problem_topic: most_errors_topic,
      count: by_topic[most_errors_topic]&.count || 0
    }
  end

  def analyze_distractor_susceptibility(user)
    # 사용자가 자주 선택하는 함정 선택지 분석
    wrong_answers = user.wrong_answers.recent.limit(30)
    distractor_analysis = wrong_answers.group_by(&:selected_answer).map do |answer, group|
      {
        distractor: answer,
        frequency: group.count,
        percentage: (group.count.to_f / wrong_answers.count * 100).round(2)
      }
    end

    distractor_analysis.sort_by { |d| d[:frequency] }.reverse
  end

  def build_concept_hierarchy(analysis_result)
    related = analysis_result.related_concepts_with_details

    hierarchy = {
      primary: related.select { |r| r[:relationship_type] == 'primary' },
      supporting: related.select { |r| r[:relationship_type] == 'supporting' },
      advanced: related.select { |r| r[:relationship_type] == 'advanced' }
    }

    hierarchy
  end

  def identify_gaps_in_prerequisite_chain(analysis_result)
    prerequisites = analysis_result.prerequisites
    gaps = prerequisites.select { |p| p[:mastery_level].to_f < 0.6 }

    gaps.map { |g| { concept: g[:name], gap_score: 1.0 - g[:mastery_level].to_f } }
  end

  def find_critical_junctions(analysis_result)
    # 여러 개념이 만나는 중요 지점 찾기
    related = analysis_result.related_concepts_with_details
    related.select { |r| r[:relevance_score] > 0.7 }
  end

  def identify_weak_concepts(user, analysis_result)
    prerequisites = analysis_result.prerequisites
    weak = prerequisites.select do |p|
      mastery = user.user_masteries.find_by(knowledge_node_id: p[:concept_id])
      (mastery&.mastery_level || 0.0) < 0.7
    end

    weak.map do |w|
      {
        concept_id: w[:concept_id],
        concept_name: w[:name],
        mastery_level: (user.user_masteries.find_by(knowledge_node_id: w[:concept_id])&.mastery_level || 0.0),
        priority: w[:relevance_score]
      }
    end.sort_by { |w| w[:priority] }.reverse
  end

  def plan_learning_steps(weak_concepts, analysis_result, study_set, user)
    weak_concepts.map.with_index do |concept, index|
      {
        step: index + 1,
        concept: concept[:concept_name],
        concept_id: concept[:concept_id],
        action: determine_action(concept[:mastery_level]),
        estimated_minutes: estimate_concept_time(concept),
        resources: find_learning_resources(concept[:concept_id], study_set),
        prerequisites_before_this: find_prerequisites_for_concept(concept[:concept_id])
      }
    end
  end

  def select_practice_questions(weak_concepts, study_set, user)
    questions_by_concept = {}

    weak_concepts.each do |concept|
      # 같은 주제의 문제 선정 (사용자가 틀린 것 포함)
      practice_qs = Question.where(
        study_material_id: study_set.study_materials.pluck(:id),
        topic: concept[:concept_name]
      ).sample(3)

      questions_by_concept[concept[:concept_name]] = practice_qs.map do |q|
        {
          question_id: q.id,
          question: q.content,
          difficulty: q.difficulty,
          is_previously_wrong: user.wrong_answers.exists?(question_id: q.id)
        }
      end
    end

    questions_by_concept
  end

  def estimate_learning_time(learning_path_steps, practice_questions)
    path_time = learning_path_steps.sum { |step| step[:estimated_minutes] || 10 }
    practice_time = practice_questions.values.sum { |qs| qs.count * 5 }

    ((path_time + practice_time) / 60.0).round(1)
  end

  def plan_difficulty_progression(weak_concepts)
    # 난이도 점진적 상향
    weak_concepts.map.with_index do |concept, index|
      {
        stage: index + 1,
        concept: concept[:concept_name],
        difficulty_level: [1, 2, 3, 4, 5][(index / 2).min(4)]
      }
    end
  end

  def estimate_improvement(weak_concepts)
    # 학습 후 예상 숙달도 개선
    weak_concepts.sum { |c| (1.0 - c[:mastery_level]) * 0.3 } / weak_concepts.count
  end

  def calculate_success_probability(user, weak_concepts)
    # 사용자의 학습 이력 기반 성공 확률
    user_learning_capacity = user.exam_answers.where(is_correct: true).count.to_f / (user.exam_answers.count + 1)
    concept_difficulty = weak_concepts.average { |c| c[:mastery_level] }

    (user_learning_capacity * 0.6 + concept_difficulty * 0.4).round(3)
  end

  def determine_action(mastery_level)
    case mastery_level
    when 0...0.3
      'intensive_review'
    when 0.3...0.6
      'focused_practice'
    else
      'maintenance_practice'
    end
  end

  def estimate_concept_time(concept)
    case concept[:mastery_level]
    when 0...0.3
      30 # 처음부터 배우기
    when 0.3...0.6
      15 # 복습 및 강화
    else
      5 # 유지 학습
    end
  end

  def find_learning_resources(concept_id, study_set)
    # 해당 개념 관련 학습 자료 찾기
    concept = KnowledgeNode.find(concept_id)

    study_set.questions.select do |q|
      q.document_chunks.exists? # 관련 청크가 있는 문제
    end.take(5)
  end

  def find_prerequisites_for_concept(concept_id)
    concept = KnowledgeNode.find(concept_id)
    concept.prerequisites.map(&:name)
  end

  def get_concept_accuracy(user, question)
    # 사용자가 이 개념 관련 문제를 푼 정확도
    related_answers = user.exam_answers.joins(:question).where(questions: { topic: question.topic })
    return 50 if related_answers.count.zero?

    (related_answers.where(is_correct: true).count.to_f / related_answers.count * 100).round(2)
  end
end
