class GraphAnalysisService
  attr_reader :user, :study_material

  def initialize(user, study_material)
    @user = user
    @study_material = study_material
  end

  # 약점 분석 (빨간 노드 식별)
  def identify_weak_areas
    masteries = UserMastery.where(user_id: user.id)
                           .joins(:knowledge_node)
                           .where(knowledge_nodes: { study_material_id: study_material.id })

    weak_areas = masteries.where(color: 'red').order(mastery_level: :asc)

    weak_areas.map do |mastery|
      {
        node: mastery.knowledge_node,
        mastery_level: mastery.mastery_level,
        attempts: mastery.attempts,
        accuracy: mastery.accuracy,
        status: mastery.status
      }
    end
  end

  # 강점 식별 (초록 노드)
  def identify_strong_areas
    masteries = UserMastery.where(user_id: user.id)
                           .joins(:knowledge_node)
                           .where(knowledge_nodes: { study_material_id: study_material.id })

    strong_areas = masteries.where(color: 'green').order(mastery_level: :desc)

    strong_areas.map do |mastery|
      {
        node: mastery.knowledge_node,
        mastery_level: mastery.mastery_level,
        attempts: mastery.attempts,
        accuracy: mastery.accuracy,
        status: mastery.status
      }
    end
  end

  # 학습 경로 추천
  def recommend_learning_path(limit: 10)
    weak_nodes = identify_weak_areas.map { |w| w[:node] }
    return [] if weak_nodes.empty?

    # 약점에서 필요한 선수 개념들
    prerequisite_concepts = weak_nodes.flat_map(&:all_prerequisites).uniq

    # 아직 학습하지 않은 선수 개념 찾기
    untested_prerequisites = prerequisite_concepts.select do |concept|
      mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: concept.id)
      mastery.nil? || mastery.status == 'untested'
    end

    # 중요도와 난이도 순으로 정렬
    untested_prerequisites
      .sort_by { |n| [-n.importance, n.difficulty] }
      .first(limit)
  end

  # 개념 맵 생성 (JSON 형식)
  def generate_concept_map
    nodes = KnowledgeNode.where(study_material_id: study_material.id, active: true)
    edges = KnowledgeEdge.joins(:knowledge_node).where(
      knowledge_nodes: { study_material_id: study_material.id },
      active: true
    )

    node_data = nodes.map do |node|
      mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: node.id)
      {
        id: node.id,
        name: node.name,
        level: node.level,
        difficulty: node.difficulty,
        importance: node.importance,
        color: mastery&.color || 'gray',
        mastery_level: mastery&.mastery_level || 0.0,
        x: rand(0..1000), # 3D visualization을 위한 좌표 (실제로는 레이아웃 알고리즘 사용)
        y: rand(0..1000),
        z: rand(0..1000)
      }
    end

    edge_data = edges.map do |edge|
      {
        id: edge.id,
        source: edge.knowledge_node_id,
        target: edge.related_node_id,
        type: edge.relationship_type,
        weight: edge.weight,
        label: edge.relationship_name
      }
    end

    {
      nodes: node_data,
      edges: edge_data,
      layout: 'force-directed'
    }
  end

  # 난이도 계산 (가중 평균)
  def calculate_overall_difficulty
    nodes = KnowledgeNode.where(study_material_id: study_material.id, active: true)
    return 0 if nodes.empty?

    total_weight = 0
    weighted_sum = 0

    nodes.each do |node|
      # 중요도를 가중치로 사용
      weight = node.importance
      weighted_sum += node.difficulty * weight
      total_weight += weight
    end

    (weighted_sum.to_f / total_weight).round(2)
  end

  # 학습 진도
  def calculate_progress_percentage
    all_masteries = UserMastery.where(user_id: user.id)
                               .joins(:knowledge_node)
                               .where(knowledge_nodes: { study_material_id: study_material.id })

    return 0 if all_masteries.empty?

    mastered_count = all_masteries.where(color: 'green').count
    (mastered_count.to_f / all_masteries.count * 100).round(1)
  end

  # 추천 학습 시간
  def estimate_study_time_needed(weak_area_node)
    mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: weak_area_node.id)
    return 0 unless mastery

    # 정확도에 따른 추정 시간
    base_time = weak_area_node.difficulty * 10 # 10분 x 난이도
    accuracy_factor = 1.0 - (mastery.accuracy / 100.0)

    (base_time * accuracy_factor).round(0)
  end

  # 재학습 필요 개념
  def identify_review_needed(days: 7)
    masteries = UserMastery.where(user_id: user.id)
                           .joins(:knowledge_node)
                           .where(knowledge_nodes: { study_material_id: study_material.id })

    # 최근 X일 동안 테스트되지 않았거나, 정확도가 낮은 개념
    review_needed = masteries.select do |m|
      m.days_since_last_test.nil? || m.days_since_last_test > days || m.accuracy < 70
    end

    review_needed
      .sort_by { |m| [m.days_since_last_test || Float::INFINITY, -m.importance] }
      .map { |m| m.knowledge_node }
  end

  # 대시보드 요약
  def dashboard_summary
    {
      progress_percentage: calculate_progress_percentage,
      weak_areas_count: identify_weak_areas.length,
      strong_areas_count: identify_strong_areas.length,
      recommended_path: recommend_learning_path(limit: 5),
      review_needed: identify_review_needed(days: 7).first(5),
      overall_difficulty: calculate_overall_difficulty,
      recent_activity: recent_activity_summary
    }
  end

  # 최근 활동 요약
  def recent_activity_summary
    recent_masteries = UserMastery.where(user_id: user.id)
                                 .joins(:knowledge_node)
                                 .where(knowledge_nodes: { study_material_id: study_material.id })
                                 .where('last_tested_at > ?', 7.days.ago)
                                 .order(last_tested_at: :desc)
                                 .limit(10)

    {
      total_attempts_7d: recent_masteries.sum(:attempts),
      avg_accuracy_7d: recent_masteries.any? ? recent_masteries.average(:accuracy).round(1) : 0,
      recently_tested: recent_masteries.map do |m|
        {
          name: m.knowledge_node.name,
          accuracy: m.accuracy,
          last_tested_at: m.last_tested_at,
          mastery_level: m.mastery_level
        }
      end
    }
  end

  # 개념 간 의존성 분석
  def analyze_dependency_chains
    weak_areas = identify_weak_areas.map { |w| w[:node] }
    return {} if weak_areas.empty?

    dependency_chains = {}

    weak_areas.each do |weak_node|
      prerequisites = weak_node.all_prerequisites
      next if prerequisites.empty?

      # 선수 개념들의 숙달도 확인
      prerequisite_masteries = prerequisites.map do |prereq|
        mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: prereq.id)
        {
          concept: prereq.name,
          mastery_level: mastery&.mastery_level || 0.0,
          status: mastery&.status || 'untested'
        }
      end

      dependency_chains[weak_node.name] = {
        prerequisites: prerequisite_masteries,
        blocker: prerequisite_masteries.any? { |p| p[:status] == 'weak' }
      }
    end

    dependency_chains
  end

  # 개인화된 학습 전략 제시
  def suggest_learning_strategy
    weak_areas = identify_weak_areas
    return nil if weak_areas.empty?

    primary_weakness = weak_areas.first
    node = primary_weakness[:node]
    prerequisites = node.all_prerequisites

    strategy = {
      focus_area: node.name,
      current_mastery: primary_weakness[:mastery_level],
      current_accuracy: primary_weakness[:accuracy],
      blocker_concepts: prerequisites.select { |p|
        mastery = UserMastery.find_by(user_id: user.id, knowledge_node_id: p.id)
        mastery&.status == 'weak' || mastery.nil?
      }.map(&:name),
      next_steps: [],
      estimated_time_hours: (estimate_study_time_needed(node) / 60.0).round(1)
    }

    # 다음 스텝 제시
    if strategy[:blocker_concepts].any?
      strategy[:next_steps] = [
        "먼저 다음 선수 개념을 학습하세요: #{strategy[:blocker_concepts].join(', ')}",
        "각 선수 개념마다 5-10개의 문제를 풀어보세요"
      ]
    else
      strategy[:next_steps] = [
        "#{node.name} 개념을 복습하세요",
        "관련 문제를 풀어서 실전 감각을 익혀보세요",
        "정확도가 80% 이상이 될 때까지 반복 학습하세요"
      ]
    end

    strategy
  end
end
