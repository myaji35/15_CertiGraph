class KnowledgeGraphService
  attr_reader :study_material, :llm_client

  def initialize(study_material)
    @study_material = study_material
    @llm_client = OpenAIClient.new
  end

  # 질문에서 개념 추출 및 그래프 업데이트
  def extract_and_build_graph_from_question(question)
    concepts = extract_concepts(question)
    relationships = extract_relationships(question, concepts)

    # 개념 노드 생성
    concept_nodes = concepts.map { |concept| create_or_update_node(concept) }

    # 관계 생성
    relationships.each do |rel|
      create_relationship(rel, concept_nodes)
    end

    concept_nodes
  end

  # LLM을 사용한 개념 추출
  def extract_concepts(question)
    prompt = build_concept_extraction_prompt(question)
    response = @llm_client.chat(
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 500
    )

    parse_concepts_response(response)
  rescue StandardError => e
    Rails.logger.error("Concept extraction failed: #{e.message}")
    []
  end

  # LLM을 사용한 관계 추출
  def extract_relationships(question, concepts)
    return [] if concepts.empty?

    prompt = build_relationship_extraction_prompt(question, concepts)
    response = @llm_client.chat(
      model: 'gpt-4o-mini',
      messages: [{ role: 'user', content: prompt }],
      temperature: 0.3,
      max_tokens: 800
    )

    parse_relationships_response(response)
  rescue StandardError => e
    Rails.logger.error("Relationship extraction failed: #{e.message}")
    []
  end

  # 개념 노드 생성 또는 업데이트
  def create_or_update_node(concept_data)
    node = KnowledgeNode.find_or_create_by(
      study_material_id: study_material.id,
      name: concept_data[:name]
    ) do |n|
      n.level = concept_data[:level] || 'concept'
      n.description = concept_data[:description]
      n.difficulty = concept_data[:difficulty] || 3
      n.importance = concept_data[:importance] || 3
      n.parent_name = concept_data[:parent_name]
      n.metadata = concept_data[:metadata] || {}
    end

    # 기존 노드 업데이트
    node.update(
      description: concept_data[:description] || node.description,
      difficulty: concept_data[:difficulty] || node.difficulty,
      importance: concept_data[:importance] || node.importance
    )

    node
  end

  # 관계 생성
  def create_relationship(relationship_data, concept_nodes)
    from_name = relationship_data[:from]
    to_name = relationship_data[:to]
    rel_type = relationship_data[:type]
    weight = relationship_data[:weight] || 0.6
    reasoning = relationship_data[:reasoning]

    from_node = concept_nodes.find { |n| n.name.downcase == from_name.downcase }
    to_node = concept_nodes.find { |n| n.name.downcase == to_name.downcase }

    return unless from_node && to_node

    KnowledgeEdge.find_or_create_by(
      knowledge_node_id: from_node.id,
      related_node_id: to_node.id,
      relationship_type: rel_type
    ) do |edge|
      edge.weight = weight
      edge.reasoning = reasoning
    end
  end

  # 온톨로지 계층 구조 구축
  def build_ontology_hierarchy
    # Subject -> Chapter -> Concept -> Detail 구조 생성
    subjects = KnowledgeNode.where(study_material_id: study_material.id, level: 'subject')

    subjects.each do |subject|
      chapters = KnowledgeNode.where(
        study_material_id: study_material.id,
        level: 'chapter',
        parent_name: subject.name
      )

      chapters.each do |chapter|
        concepts = KnowledgeNode.where(
          study_material_id: study_material.id,
          level: 'concept',
          parent_name: chapter.name
        )

        # Chapter -> Concept 관계 생성
        concepts.each do |concept|
          chapter.add_part_of(concept, reasoning: "Hierarchical relationship")
        end

        # Subject -> Chapter 관계 생성
        subject.add_part_of(chapter, reasoning: "Hierarchical relationship")
      end
    end
  end

  # 경로 탐색 (BFS)
  def find_learning_path(from_node, to_node)
    visited = Set.new
    queue = [[from_node, [from_node]]]

    while queue.any?
      current_node, path = queue.shift
      next if visited.include?(current_node.id)

      visited.add(current_node.id)

      return path if current_node.id == to_node.id

      current_node.related_nodes.each do |neighbor|
        queue.push([neighbor, path + [neighbor]]) unless visited.include?(neighbor.id)
      end
    end

    nil
  end

  # 그래프 통계
  def graph_statistics
    nodes = KnowledgeNode.where(study_material_id: study_material.id, active: true)
    edges = KnowledgeEdge.joins(:knowledge_node).where(
      knowledge_nodes: { study_material_id: study_material.id },
      active: true
    )

    {
      total_nodes: nodes.count,
      total_edges: edges.count,
      nodes_by_level: nodes.group_by(&:level).map { |k, v| [k, v.count] }.to_h,
      nodes_by_difficulty: nodes.group_by(&:difficulty).map { |k, v| [k, v.count] }.to_h,
      relationships_by_type: edges.group_by(&:relationship_type).map { |k, v| [k, v.count] }.to_h,
      avg_connections_per_node: edges.count > 0 ? (edges.count.to_f / nodes.count).round(2) : 0
    }
  end

  # 그래프 데이터 내보내기
  def export_graph_as_json(user = nil)
    nodes = KnowledgeNode.where(study_material_id: study_material.id, active: true)
    edges = KnowledgeEdge.joins(:knowledge_node).where(
      knowledge_nodes: { study_material_id: study_material.id },
      active: true
    )

    {
      nodes: nodes.map { |n| n.to_detailed_json(user) },
      edges: edges.map(&:to_json),
      stats: graph_statistics
    }
  end

  private

  def build_concept_extraction_prompt(question)
    <<~PROMPT
      다음 시험 문제에서 핵심 개념들을 추출하세요.

      문제:
      #{question.content}

      각 개념을 다음 JSON 형식으로 반환하세요:
      [
        {
          "name": "개념명",
          "level": "concept|detail|chapter",
          "description": "설명",
          "difficulty": 1-5,
          "importance": 1-5,
          "parent_name": "상위개념"
        }
      ]

      개념은 명사 형태이고, 이 시험 문제의 핵심 내용을 나타내야 합니다.
      JSON만 반환하세요.
    PROMPT
  end

  def build_relationship_extraction_prompt(question, concepts)
    concept_names = concepts.map { |c| c[:name] }.join(', ')

    <<~PROMPT
      다음 개념들 사이의 관계를 찾아보세요.

      개념: #{concept_names}
      문제: #{question.content}

      각 관계를 다음 JSON 형식으로 반환하세요:
      [
        {
          "from": "개념1",
          "to": "개념2",
          "type": "prerequisite|related_to|part_of|example_of|leads_to",
          "weight": 0.0-1.0,
          "reasoning": "관계 설명"
        }
      ]

      JSON만 반환하세요.
    PROMPT
  end

  def parse_concepts_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] unless content

    # JSON 추출 (```json ... ``` 형식 대응)
    json_match = content.match(/\[[\s\S]*\]/)
    return [] unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse concepts: #{e.message}")
    []
  end

  def parse_relationships_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    return [] unless content

    # JSON 추출
    json_match = content.match(/\[[\s\S]*\]/)
    return [] unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse relationships: #{e.message}")
    []
  end
end
