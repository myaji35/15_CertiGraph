class ConceptNormalizationService
  attr_reader :study_material, :openai_client

  def initialize(study_material)
    @study_material = study_material
    @openai_client = OpenaiClient.new
  end

  # Normalize all concepts in the study material
  def normalize_all_concepts
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active
    normalized_count = 0

    concepts.find_each do |concept|
      if normalize_concept(concept)
        normalized_count += 1
      end
    end

    # Detect and merge duplicates
    merge_count = detect_and_merge_duplicates

    # Detect synonyms
    synonym_count = detect_synonyms

    {
      total_concepts: concepts.count,
      normalized: normalized_count,
      merged: merge_count,
      synonyms_detected: synonym_count
    }
  end

  # Normalize a single concept
  def normalize_concept(concept)
    return false if concept.normalized_name.present?

    normalized = KnowledgeNode.normalize_term(concept.name)
    concept.update(normalized_name: normalized)

    true
  rescue StandardError => e
    Rails.logger.error("Failed to normalize concept #{concept.id}: #{e.message}")
    false
  end

  # Detect and merge duplicate concepts
  def detect_and_merge_duplicates
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active
    merge_count = 0

    # Group by normalized name
    grouped = concepts.group_by(&:normalized_name)

    grouped.each do |normalized_name, nodes|
      next if nodes.size < 2

      # Keep the primary one or the one with most connections
      primary = nodes.find(&:is_primary) || nodes.max_by { |n| n.question_concepts.count }
      duplicates = nodes - [primary]

      duplicates.each do |duplicate|
        merge_concepts(primary, duplicate)
        merge_count += 1
      end
    end

    merge_count
  end

  # Merge duplicate concept into primary
  def merge_concepts(primary, duplicate)
    ActiveRecord::Base.transaction do
      # Move question_concepts
      QuestionConcept.where(knowledge_node_id: duplicate.id).find_each do |qc|
        existing = QuestionConcept.find_by(
          question_id: qc.question_id,
          knowledge_node_id: primary.id
        )

        if existing
          # Update if new one has higher importance
          if qc.importance_level > existing.importance_level
            existing.update(
              importance_level: qc.importance_level,
              relevance_score: [qc.relevance_score, existing.relevance_score].max
            )
          end
          qc.destroy
        else
          qc.update(knowledge_node_id: primary.id)
        end
      end

      # Move synonyms
      duplicate.concept_synonyms.each do |syn|
        primary.add_synonym(
          syn.synonym_name,
          type: syn.synonym_type,
          similarity: syn.similarity_score,
          source: syn.source
        ) unless primary.concept_synonyms.exists?(synonym_name: syn.synonym_name)
      end

      # Move edges
      duplicate.outgoing_edges.each do |edge|
        next if primary.outgoing_edges.exists?(related_node_id: edge.related_node_id)
        edge.update(knowledge_node_id: primary.id)
      end

      duplicate.incoming_edges.each do |edge|
        next if primary.incoming_edges.exists?(knowledge_node_id: edge.knowledge_node_id)
        edge.update(related_node_id: primary.id)
      end

      # Merge metadata
      primary.update(
        description: primary.description.presence || duplicate.description,
        definition: primary.definition.presence || duplicate.definition,
        examples: (primary.examples + duplicate.examples).uniq,
        frequency: primary.frequency + duplicate.frequency,
        difficulty: [(primary.difficulty + duplicate.difficulty) / 2, 5].min,
        importance: [primary.importance, duplicate.importance].max
      )

      # Deactivate duplicate
      duplicate.update(active: false)

      Rails.logger.info("Merged concept #{duplicate.name} into #{primary.name}")
    end
  rescue StandardError => e
    Rails.logger.error("Failed to merge concepts: #{e.message}")
    raise ActiveRecord::Rollback
  end

  # Detect synonyms using AI
  def detect_synonyms
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active.primary_concepts
    synonym_count = 0

    # Process in batches
    concepts.in_batches(of: 10) do |batch|
      batch_names = batch.pluck(:id, :name)

      synonyms = detect_synonyms_in_batch(batch_names)

      synonyms.each do |synonym_data|
        concept = batch.find(synonym_data[:concept_id])
        synonym_data[:synonyms].each do |syn|
          if concept.add_synonym(syn, source: 'ai_extracted', similarity: 0.9)
            synonym_count += 1
          end
        end
      end
    end

    synonym_count
  end

  # Detect synonyms in a batch of concepts
  def detect_synonyms_in_batch(concept_names)
    prompt = build_synonym_detection_prompt(concept_names)

    response = @openai_client.reason_with_gpt4o(prompt, temperature: 0.2)
    parse_synonym_response(response)
  rescue StandardError => e
    Rails.logger.error("Synonym detection error: #{e.message}")
    []
  end

  # Build prompt for synonym detection
  def build_synonym_detection_prompt(concept_names)
    concepts_list = concept_names.map { |id, name| "#{id}: #{name}" }.join("\n")

    <<~PROMPT
      다음 개념들에 대해 동의어, 약어, 유사 용어를 찾아주세요:

      #{concepts_list}

      각 개념에 대해 다음을 제공하세요:
      - 동의어 (완전히 같은 의미)
      - 약어 (예: API, HTTP)
      - 관련 용어 (유사하지만 약간 다른 의미)

      다음 JSON 형식으로 응답:
      [
        {
          "concept_id": 1,
          "synonyms": ["동의어1", "약어1", "관련용어1"]
        }
      ]

      빈 배열이면 synonyms를 생략하세요.
      JSON만 반환하세요.
    PROMPT
  end

  # Parse synonym detection response
  def parse_synonym_response(response)
    json_match = response.match(/\[[\s\S]*\]/)
    return [] unless json_match

    JSON.parse(json_match[0])
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse synonym response: #{e.message}")
    []
  end

  # Find and link related concepts by semantic similarity
  def find_related_concepts_by_similarity(concept, threshold: 0.7)
    return [] unless concept.description.present?

    # Generate embedding for the concept
    concept_embedding = @openai_client.generate_embedding(
      "#{concept.name}: #{concept.description}"
    )

    # Find similar concepts
    other_concepts = KnowledgeNode.where(study_material_id: @study_material.id)
                                   .where.not(id: concept.id)
                                   .where.not(description: nil)
                                   .active

    similar_concepts = []

    other_concepts.find_each do |other|
      other_embedding = @openai_client.generate_embedding(
        "#{other.name}: #{other.description}"
      )

      similarity = cosine_similarity(concept_embedding, other_embedding)

      if similarity >= threshold
        similar_concepts << {
          concept: other,
          similarity: similarity
        }
      end
    end

    similar_concepts.sort_by { |s| -s[:similarity] }
  rescue StandardError => e
    Rails.logger.error("Similarity search error: #{e.message}")
    []
  end

  # Standardize concept names using common patterns
  def standardize_concept_names
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active
    standardized_count = 0

    concepts.find_each do |concept|
      standardized = standardize_name(concept.name)

      if standardized != concept.name
        # Add original as synonym
        concept.add_synonym(concept.name, type: 'alias', source: 'manual')

        # Update name
        concept.update(name: standardized)
        standardized_count += 1
      end
    end

    standardized_count
  end

  private

  # Standardize concept name
  def standardize_name(name)
    # Remove extra spaces
    standardized = name.strip.gsub(/\s+/, ' ')

    # Capitalize consistently
    # (You can add more rules based on your domain)
    standardized
  end

  # Calculate cosine similarity between two vectors
  def cosine_similarity(vec1, vec2)
    return 0.0 if vec1.size != vec2.size

    dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
    magnitude1 = Math.sqrt(vec1.map { |x| x**2 }.sum)
    magnitude2 = Math.sqrt(vec2.map { |x| x**2 }.sum)

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    dot_product / (magnitude1 * magnitude2)
  end
end
