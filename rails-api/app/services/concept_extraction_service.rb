class ConceptExtractionService
  attr_reader :study_material, :openai_client

  def initialize(study_material)
    @study_material = study_material
    @openai_client = OpenaiClient.new
  end

  # Extract concepts from a single question
  def extract_from_question(question)
    return [] if question.content.blank?

    concepts_data = call_gpt4o_for_concept_extraction(question)
    return [] if concepts_data.empty?

    # Create or update knowledge nodes
    created_concepts = []
    concepts_data.each do |concept_data|
      node = create_or_update_concept_node(concept_data)
      if node
        link_question_to_concept(question, node, concept_data)
        created_concepts << node
      end
    end

    # Update frequency counters
    created_concepts.each(&:update_frequency!)

    created_concepts
  rescue StandardError => e
    Rails.logger.error("Concept extraction failed for question #{question.id}: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    []
  end

  # Extract concepts from all questions in study material
  def extract_from_all_questions
    questions = @study_material.questions
    total = questions.count
    processed = 0
    extracted = []

    questions.find_each do |question|
      concepts = extract_from_question(question)
      extracted.concat(concepts)
      processed += 1

      Rails.logger.info("Processed #{processed}/#{total} questions")
    end

    # Build concept hierarchy
    build_hierarchy

    # Extract relationships between concepts
    extract_relationships

    {
      total_questions: total,
      processed_questions: processed,
      unique_concepts: extracted.uniq.count,
      total_concept_extractions: extracted.count
    }
  end

  # Build hierarchical relationships (Subject -> Chapter -> Concept)
  def build_hierarchy
    concepts = KnowledgeNode.where(study_material_id: @study_material.id)

    concepts.by_level('concept').find_each do |concept|
      next unless concept.parent_name.present?

      parent = concepts.find_by(name: concept.parent_name, level: 'chapter')
      parent ||= concepts.find_by(name: concept.parent_name, level: 'subject')

      if parent
        parent.add_part_of(concept, weight: 0.9, reasoning: 'Hierarchical structure')
      end
    end

    concepts.by_level('chapter').find_each do |chapter|
      next unless chapter.parent_name.present?

      subject = concepts.find_by(name: chapter.parent_name, level: 'subject')
      if subject
        subject.add_part_of(chapter, weight: 0.95, reasoning: 'Hierarchical structure')
      end
    end
  end

  # Extract relationships between concepts based on question context
  def extract_relationships
    questions = @study_material.questions.includes(:question_concepts, :knowledge_nodes)

    questions.find_each do |question|
      nodes = question.knowledge_nodes.to_a
      next if nodes.size < 2

      # For each pair of concepts in the same question, find relationships
      nodes.combination(2).each do |node1, node2|
        relationship_data = extract_relationship_between_concepts(question, node1, node2)

        if relationship_data[:type].present?
          create_concept_relationship(node1, node2, relationship_data)
        end
      end
    end
  end

  private

  # Call GPT-4o for concept extraction
  def call_gpt4o_for_concept_extraction(question)
    prompt = build_extraction_prompt(question)

    response = @openai_client.reason_with_gpt4o(
      prompt,
      temperature: 0.3
    )

    parse_extraction_response(response)
  rescue StandardError => e
    Rails.logger.error("GPT-4o concept extraction error: #{e.message}")
    []
  end

  # Build detailed prompt for concept extraction
  def build_extraction_prompt(question)
    <<~PROMPT
      당신은 시험 문제에서 핵심 개념을 추출하는 전문가입니다.

      다음 문제를 분석하고 핵심 개념들을 추출하세요:

      **문제:**
      #{question.content}

      #{question.passage.present? ? "**지문:**\n#{question.passage}\n" : ''}

      **요구사항:**
      1. 이 문제를 이해하고 풀기 위해 필요한 핵심 개념들을 추출하세요
      2. 각 개념에 대해 다음 정보를 제공하세요:
         - name: 개념의 정확한 이름 (명사형)
         - level: concept (기본 개념) / detail (세부 개념) / chapter (장/단원)
         - description: 개념에 대한 간단한 설명 (1-2문장)
         - definition: 개념의 정의 (선택사항)
         - difficulty: 1-5 (1=매우 쉬움, 5=매우 어려움)
         - importance: 1-10 (이 문제에서의 중요도)
         - parent_name: 상위 개념 이름 (있는 경우)
         - category: fundamental / advanced / specialized
         - examples: 예시 목록 (배열)
         - synonyms: 동의어/유사 용어 목록 (배열)
         - is_primary: 이 문제의 주요 개념 여부 (true/false)

      다음 JSON 형식으로 응답하세요:
      {
        "concepts": [
          {
            "name": "개념명",
            "level": "concept",
            "description": "설명",
            "definition": "정의",
            "difficulty": 3,
            "importance": 8,
            "parent_name": "상위개념",
            "category": "fundamental",
            "examples": ["예시1", "예시2"],
            "synonyms": ["동의어1", "동의어2"],
            "is_primary": true
          }
        ]
      }

      **주의사항:**
      - 최소 1개, 최대 5개의 개념을 추출하세요
      - 개념명은 명확하고 표준화된 용어를 사용하세요
      - JSON만 반환하고 다른 설명은 하지 마세요
    PROMPT
  end

  # Parse GPT-4o response
  def parse_extraction_response(response)
    return [] if response.blank?

    # Extract JSON from response
    json_match = response.match(/\{[\s\S]*\}/)
    return [] unless json_match

    data = JSON.parse(json_match[0])
    concepts = data['concepts'] || []

    concepts.map do |concept|
      {
        name: concept['name'],
        level: concept['level'] || 'concept',
        description: concept['description'],
        definition: concept['definition'],
        difficulty: concept['difficulty']&.to_i || 3,
        importance: concept['importance']&.to_i || 5,
        parent_name: concept['parent_name'],
        category: concept['category'],
        examples: concept['examples'] || [],
        synonyms: concept['synonyms'] || [],
        is_primary: concept['is_primary'] || false,
        relevance_score: calculate_relevance_score(concept)
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse concept extraction response: #{e.message}")
    []
  end

  # Calculate relevance score based on importance and other factors
  def calculate_relevance_score(concept_data)
    importance = concept_data['importance']&.to_f || 5.0
    is_primary = concept_data['is_primary'] ? 1.0 : 0.5

    # Normalize to 0.0-1.0 range
    base_score = (importance / 10.0) * is_primary
    [base_score, 1.0].min
  end

  # Create or update concept node
  def create_or_update_concept_node(concept_data)
    normalized_name = KnowledgeNode.normalize_term(concept_data[:name])

    node = KnowledgeNode.find_or_initialize_by(
      study_material_id: @study_material.id,
      normalized_name: normalized_name
    )

    node.assign_attributes(
      name: concept_data[:name],
      level: concept_data[:level],
      description: concept_data[:description] || node.description,
      definition: concept_data[:definition] || node.definition,
      difficulty: concept_data[:difficulty],
      importance: [concept_data[:importance], node.importance || 0].max,
      parent_name: concept_data[:parent_name],
      concept_category: concept_data[:category],
      examples: (node.examples || []) | (concept_data[:examples] || []),
      is_primary: concept_data[:is_primary],
      extraction_confidence: 0.85, # GPT-4o confidence
      active: true
    )

    node.save!

    # Add synonyms
    (concept_data[:synonyms] || []).each do |synonym|
      node.add_synonym(synonym, source: 'ai_extracted', similarity: 0.9)
    end

    node
  rescue StandardError => e
    Rails.logger.error("Failed to create concept node: #{e.message}")
    nil
  end

  # Link question to concept
  def link_question_to_concept(question, node, concept_data)
    QuestionConcept.find_or_create_by!(
      question_id: question.id,
      knowledge_node_id: node.id
    ) do |qc|
      qc.importance_level = concept_data[:importance]
      qc.relevance_score = concept_data[:relevance_score]
      qc.is_primary_concept = concept_data[:is_primary]
      qc.extraction_method = 'ai'
      qc.metadata = { extracted_at: Time.current, model: 'gpt-4o' }
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.warn("Question-Concept link already exists: #{e.message}")
  end

  # Extract relationship between two concepts
  def extract_relationship_between_concepts(question, node1, node2)
    prompt = build_relationship_prompt(question, node1, node2)

    response = @openai_client.reason_with_gpt4o_mini(prompt, temperature: 0.3)
    parse_relationship_response(response)
  rescue StandardError => e
    Rails.logger.error("Relationship extraction error: #{e.message}")
    { type: nil }
  end

  # Build prompt for relationship extraction
  def build_relationship_prompt(question, node1, node2)
    <<~PROMPT
      다음 두 개념 사이의 관계를 분석하세요:

      개념1: #{node1.name}
      개념2: #{node2.name}

      문제 컨텍스트: #{question.content[0..200]}

      관계 유형을 다음 중 하나로 분류하세요:
      - prerequisite: 개념1이 개념2의 선수 지식
      - related_to: 서로 관련된 개념
      - part_of: 개념1이 개념2의 일부
      - leads_to: 개념1이 개념2로 이어짐
      - none: 관계 없음

      JSON 형식으로 응답:
      { "type": "prerequisite", "weight": 0.8, "reasoning": "이유" }
    PROMPT
  end

  # Parse relationship response
  def parse_relationship_response(response)
    json_match = response.match(/\{[\s\S]*\}/)
    return { type: nil } unless json_match

    JSON.parse(json_match[0]).symbolize_keys
  rescue JSON::ParserError
    { type: nil }
  end

  # Create concept relationship
  def create_concept_relationship(node1, node2, relationship_data)
    return if relationship_data[:type] == 'none'

    KnowledgeEdge.find_or_create_by(
      knowledge_node_id: node1.id,
      related_node_id: node2.id,
      relationship_type: relationship_data[:type]
    ) do |edge|
      edge.weight = relationship_data[:weight] || 0.5
      edge.reasoning = relationship_data[:reasoning]
    end
  rescue StandardError => e
    Rails.logger.error("Failed to create relationship: #{e.message}")
  end
end
