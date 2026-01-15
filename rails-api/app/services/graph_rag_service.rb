class GraphRagService
  # GraphRAG 엔진: Multi-hop reasoning + Context-aware analysis
  # - 문제 문맥 기반 임베딩
  # - 그래프 탐색 (BFS/DFS)
  # - LLM 기반 추론
  # - 약점 탐지 알고리즘

  include Sidekiq::Worker
  sidekiq_options retry: 3, dead: true

  DEFAULT_GRAPH_DEPTH = 3
  DEFAULT_NODES_PER_LEVEL = 5
  TRAVERSAL_TIMEOUT = 30 # seconds
  CONFIDENCE_THRESHOLD = 0.6
  RELEVANCE_THRESHOLD = 0.3

  def initialize
    @openai_client = OpenaiClient.new
    @embedding_service = EmbeddingService.new
  end

  # 주요 메서드: 오답 분석 및 약점 탐지
  # @param user [User] 사용자
  # @param question [Question] 오답한 문제
  # @param selected_answer [String] 사용자가 선택한 정답
  # @param study_set [StudySet] 학습 세트
  # @return [AnalysisResult] 분석 결과
  def analyze_wrong_answer(user, question, selected_answer, study_set)
    start_time = Time.current

    begin
      Rails.logger.info("Starting GraphRAG analysis for user #{user.id}, question #{question.id}")

      # 1. 분석 결과 레코드 생성 (pending 상태)
      analysis_result = AnalysisResult.create!(
        user_id: user.id,
        question_id: question.id,
        study_set_id: study_set.id,
        analysis_type: 'wrong_answer',
        status: 'processing'
      )

      # 2. 오답 분석 (부주의 vs 개념 부족)
      error_analysis = analyze_error_type(user, question, selected_answer)

      # 3. 그래프 탐색을 통한 관련 개념 추출
      graph_analysis = traverse_concept_graph(question, study_set, user)

      # 4. LLM 기반 고수준 추론
      llm_analysis = perform_llm_reasoning(user, question, error_analysis, graph_analysis)

      # 5. 약점 점수 계산
      concept_gap_score = calculate_concept_gap_score(error_analysis, graph_analysis, llm_analysis)

      # 6. 분석 결과 저장
      analysis_result.update!(
        status: 'completed',
        error_type: error_analysis[:type],
        error_description: error_analysis[:description],
        concept_gap_score: concept_gap_score,
        related_concepts: graph_analysis[:related_concepts],
        prerequisite_concepts: graph_analysis[:prerequisites],
        dependent_concepts: graph_analysis[:dependents],
        graph_depth: graph_analysis[:depth],
        nodes_traversed: graph_analysis[:nodes_count],
        traversal_path: graph_analysis[:path],
        llm_reasoning: llm_analysis[:reasoning],
        llm_analysis_metadata: llm_analysis[:metadata],
        confidence_score: llm_analysis[:confidence],
        recommended_learning_path: llm_analysis[:learning_path],
        processing_time_ms: ((Time.current - start_time) * 1000).to_i
      )

      # 7. 분석 결과에 따른 추천 생성
      create_recommendations_from_analysis(user, study_set, analysis_result)

      # 8. 사용자 숙달도 업데이트
      update_user_mastery(user, question, error_analysis, concept_gap_score)

      Rails.logger.info("GraphRAG analysis completed for analysis_result #{analysis_result.id}")

      analysis_result
    rescue StandardError => e
      Rails.logger.error("Error in GraphRAG analysis: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      analysis_result&.mark_failed!(e.message, e.backtrace.first(10).join("\n"))
      raise e
    end
  end

  # 오답 유형 분석: 부주의 vs 개념 부족
  # @return Hash: { type: 'careless'|'concept_gap'|'mixed', description: String, confidence: Float }
  private

  def analyze_error_type(user, question, selected_answer)
    prompt = <<~PROMPT
      문제 분석 - 오답 유형 판단:

      [정답 선택지]
      #{question.answer}

      [사용자가 선택한 답]
      #{selected_answer}

      [문제 내용]
      #{question.content}

      [선택지]
      #{format_options(question)}

      [해설]
      #{question.explanation}

      [사용자 학습 이력]
      - 같은 개념 관련 문제 정답률: #{get_concept_accuracy(user, question)}%
      - 최근 7일 정답률: #{get_recent_accuracy(user)}%

      위 정보를 바탕으로:
      1. 이 오답이 "부주의(careless mistake)"인지 "개념 부족(concept gap)"인지 판단
      2. 판단 근거를 구체적으로 설명
      3. 신뢰도 점수 (0-1)를 부여

      JSON 형식으로 다음을 반환:
      {
        "type": "careless" | "concept_gap" | "mixed",
        "description": "판단 근거 설명",
        "careless_probability": 0.0-1.0,
        "concept_gap_probability": 0.0-1.0,
        "confidence": 0.0-1.0,
        "reasoning": "상세 추론 과정"
      }
    PROMPT

    response = @openai_client.chat_completion(
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      response_format: { type: 'json_object' }
    )

    parsed = JSON.parse(response)
    {
      type: determine_error_type(parsed),
      description: parsed['description'],
      careless_probability: parsed['careless_probability'],
      concept_gap_probability: parsed['concept_gap_probability'],
      confidence: parsed['confidence'],
      reasoning: parsed['reasoning']
    }
  rescue StandardError => e
    Rails.logger.error("Error analyzing error type: #{e.message}")
    { type: 'mixed', description: '분석 실패', confidence: 0.5 }
  end

  # 그래프 탐색: 관련 개념 추출
  # BFS/DFS로 knowledge graph 탐색
  def traverse_concept_graph(question, study_set, user, depth = DEFAULT_GRAPH_DEPTH)
    start_time = Time.current
    visited = Set.new
    traversal_path = []
    related_concepts_list = []

    # 1. 질문과 관련된 기본 개념 찾기 (임베딩 유사도)
    seed_concepts = find_seed_concepts(question, study_set)
    return { related_concepts: [], prerequisites: [], dependents: [], depth: 0, nodes_count: 0, path: [] } if seed_concepts.empty?

    # 2. BFS로 그래프 탐색
    queue = seed_concepts.map { |c| [c, 0] } # [concept, current_depth]
    nodes_visited = 0

    while queue.present? && (Time.current - start_time) < TRAVERSAL_TIMEOUT
      concept, current_depth = queue.shift

      next if visited.include?(concept.id)

      visited.add(concept.id)
      nodes_visited += 1

      # 탐색 경로 기록
      traversal_path << {
        concept_id: concept.id,
        concept_name: concept.name,
        depth: current_depth
      }

      # 관련 개념 추가
      related_concepts_list << {
        concept_id: concept.id,
        name: concept.name,
        level: concept.level,
        relevance_score: calculate_relevance_score(concept, question),
        relationship_type: determine_relationship_type(concept, seed_concepts.first),
        mastery_level: get_user_mastery_level(user, concept)
      }

      # 깊이가 제한에 도달하지 않았으면 관련 개념 추가
      if current_depth < depth
        next_concepts = find_related_concepts(concept)
        next_concepts.each do |related|
          queue.push([related, current_depth + 1]) unless visited.include?(related.id)
        end
      end
    end

    # 3. 선수/종속 개념 분류
    prerequisites = related_concepts_list.select do |c|
      c[:relationship_type] == 'prerequisite'
    end

    dependents = related_concepts_list.select do |c|
      c[:relationship_type] == 'dependent'
    end

    {
      related_concepts: related_concepts_list,
      prerequisites: prerequisites,
      dependents: dependents,
      depth: traversal_path.map { |p| p[:depth] }.max || 0,
      nodes_count: nodes_visited,
      path: traversal_path
    }
  end

  # LLM 기반 고수준 추론
  def perform_llm_reasoning(user, question, error_analysis, graph_analysis)
    prompt = <<~PROMPT
      복합 추론 분석:

      [문제]
      #{question.content}

      [오답 분석]
      - 오답 유형: #{error_analysis[:type]}
      - 설명: #{error_analysis[:description]}
      - 신뢰도: #{error_analysis[:confidence]}

      [관련 개념 (그래프 탐색 결과)]
      - 관련 개념 수: #{graph_analysis[:related_concepts].count}
      - 탐색 깊이: #{graph_analysis[:depth]}
      - 선수 개념: #{graph_analysis[:prerequisites].map { |p| p[:name] }.join(', ')}
      - 종속 개념: #{graph_analysis[:dependents].map { |d| d[:name] }.join(', ')}

      [사용자 학습 이력]
      - 총 시도 횟수: #{user.exam_answers.count}
      - 정답률: #{(user.exam_answers.where(is_correct: true).count.to_f / user.exam_answers.count * 100).round(2)}%
      - 최근 약점: #{identify_recent_weaknesses(user)}

      위 정보를 종합하여:
      1. 이 오답의 근본 원인이 무엇인가
      2. 어떤 선수 개념을 먼저 복습해야 하는가
      3. 이 문제를 다시 풀기 위한 학습 경로는
      4. 이 문제와 유사한 다른 문제들은 어떤 개념을 포함하는가

      다음을 JSON으로 반환:
      {
        "root_cause": "근본 원인 설명",
        "reasoning_steps": ["1단계", "2단계", ...],
        "prerequisite_topics": ["개념1", "개념2", ...],
        "learning_path": [{"step": 1, "concept": "...", "action": "..."}],
        "related_problem_concepts": ["개념1", "개념2", ...],
        "confidence": 0.0-1.0,
        "estimated_mastery_gap": 0.0-1.0
      }
    PROMPT

    response = @openai_client.chat_completion(
      model: 'gpt-4o',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.5,
      response_format: { type: 'json_object' }
    )

    parsed = JSON.parse(response)
    {
      reasoning: parsed['root_cause'],
      reasoning_steps: parsed['reasoning_steps'],
      learning_path: parsed['learning_path'],
      confidence: parsed['confidence'],
      metadata: {
        prerequisite_topics: parsed['prerequisite_topics'],
        related_problem_concepts: parsed['related_problem_concepts'],
        estimated_mastery_gap: parsed['estimated_mastery_gap']
      }
    }
  rescue StandardError => e
    Rails.logger.error("Error in LLM reasoning: #{e.message}")
    {
      reasoning: '분석 실패',
      reasoning_steps: [],
      learning_path: [],
      confidence: 0.0,
      metadata: {}
    }
  end

  # 약점 점수 계산 (0-1 정규화)
  def calculate_concept_gap_score(error_analysis, graph_analysis, llm_analysis)
    # 여러 요소를 종합하여 계산
    concept_gap_prob = error_analysis[:concept_gap_probability] || 0.5
    prerequisite_count = (graph_analysis[:prerequisites].count || 0)
    prerequisite_weight = [prerequisite_count * 0.1, 0.3].min # 최대 0.3
    llm_gap = llm_analysis[:metadata]&.fetch('estimated_mastery_gap', 0.5) || 0.5

    # 가중 평균: concept_gap_prob (40%) + prerequisite_weight (20%) + llm_gap (40%)
    gap_score = (concept_gap_prob * 0.4) + (prerequisite_weight * 0.2) + (llm_gap * 0.4)

    [gap_score.round(3), 1.0].min
  end

  # 추천 생성
  def create_recommendations_from_analysis(user, study_set, analysis_result)
    # 분석 결과를 바탕으로 학습 추천 생성
    # (별도의 ErrorAnalysisService에서 처리)
  end

  # 사용자 숙달도 업데이트
  def update_user_mastery(user, question, error_analysis, concept_gap_score)
    # 질문과 연관된 모든 개념의 숙달도 업데이트
    # (별도의 UserMasteryService에서 처리)
  end

  # ============ 헬퍼 메서드 ============

  def find_seed_concepts(question, study_set)
    # 질문과 임베딩 유사도가 높은 개념 찾기
    question_embedding = get_or_create_question_embedding(question)
    return [] unless question_embedding.present?

    concepts = KnowledgeNode.where(study_material_id: study_set.study_materials.pluck(:id))
    similar_concepts = concepts.select do |concept|
      embedding = Embedding.joins(:document_chunk)
                             .where(document_chunks: { study_material_id: concept.study_material_id })
                             .first&.vector

      next 0.0 unless embedding.present?

      calculate_similarity(question_embedding, embedding)
    end.sort_by { |_, sim| sim }.reverse.take(DEFAULT_NODES_PER_LEVEL)

    similar_concepts.map(&:first)
  rescue StandardError => e
    Rails.logger.error("Error finding seed concepts: #{e.message}")
    []
  end

  def find_related_concepts(concept)
    # 그래프에서 관련 개념 찾기
    related = concept.related_nodes + concept.dependent_nodes
    related.uniq.take(DEFAULT_NODES_PER_LEVEL)
  end

  def get_or_create_question_embedding(question)
    if question.embedding.present?
      JSON.parse(question.embedding)
    else
      @embedding_service.generate_embedding_for_question(question)
      question.reload.embedding
    end
  rescue StandardError => e
    Rails.logger.error("Error getting question embedding: #{e.message}")
    nil
  end

  def calculate_similarity(vec1, vec2)
    return 0.0 if vec1.blank? || vec2.blank?

    v1 = vec1.is_a?(String) ? JSON.parse(vec1) : vec1
    v2 = vec2.is_a?(String) ? JSON.parse(vec2) : vec2

    return 0.0 if v1.size != v2.size

    dot_product = v1.zip(v2).sum { |a, b| a * b }
    magnitude1 = Math.sqrt(v1.sum { |v| v ** 2 })
    magnitude2 = Math.sqrt(v2.sum { |v| v ** 2 })

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    (dot_product / (magnitude1 * magnitude2)).round(3)
  end

  def calculate_relevance_score(concept, question)
    # 개념과 질문의 관련도 계산 (0-1)
    # 여러 요소: 임베딩 유사도, 이전 성과, 개념 중요도
    0.5 # 실제 계산은 더 복잡할 수 있음
  end

  def determine_relationship_type(concept, seed_concept)
    edges = KnowledgeEdge.where(
      knowledge_node_id: seed_concept.id,
      related_node_id: concept.id
    ).or(
      KnowledgeEdge.where(
        knowledge_node_id: concept.id,
        related_node_id: seed_concept.id
      )
    )

    return edges.first&.relationship_type || 'related' if edges.present?

    'related'
  end

  def get_user_mastery_level(user, concept)
    mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: concept.id)
    mastery&.mastery_level || 0.0
  end

  def determine_error_type(parsed)
    careless_prob = parsed['careless_probability'] || 0.5
    concept_gap_prob = parsed['concept_gap_probability'] || 0.5

    if careless_prob > 0.6
      'careless'
    elsif concept_gap_prob > 0.6
      'concept_gap'
    else
      'mixed'
    end
  end

  def format_options(question)
    question.options.to_a.map { |k, v| "#{k}. #{v}" }.join("\n")
  end

  def get_concept_accuracy(user, question)
    # 사용자가 이 개념 관련 문제를 푼 정확도
    50 # 실제로는 데이터베이스에서 계산
  end

  def get_recent_accuracy(user)
    # 최근 7일 정답률
    user.exam_answers.where('created_at > ?', 7.days.ago).average(:is_correct) * 100
  end

  def identify_recent_weaknesses(user)
    # 최근 약점 개념 파악
    'Concept A, Concept B'
  end
end
