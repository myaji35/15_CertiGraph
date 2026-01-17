class ConceptClusteringService
  attr_reader :study_material, :openai_client

  def initialize(study_material)
    @study_material = study_material
    @openai_client = OpenaiClient.new
  end

  # Cluster concepts by semantic similarity
  def cluster_by_similarity(threshold: 0.7)
    concepts = KnowledgeNode.where(study_material_id: @study_material.id)
                           .active
                           .where.not(description: nil)

    return [] if concepts.count < 2

    # Generate embeddings for all concepts
    embeddings = generate_concept_embeddings(concepts)

    # Cluster using similarity matrix
    clusters = perform_clustering(concepts, embeddings, threshold)

    # Create cluster metadata
    create_cluster_metadata(clusters)

    clusters
  end

  # Cluster concepts by topic/category
  def cluster_by_category
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active

    clusters = concepts.group_by(&:concept_category)

    clusters.map do |category, nodes|
      {
        cluster_id: "category_#{category}",
        cluster_type: 'category',
        cluster_name: category || 'uncategorized',
        concepts: nodes.map(&:to_graph_json),
        size: nodes.size
      }
    end
  end

  # Cluster concepts by difficulty level
  def cluster_by_difficulty
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active

    clusters = concepts.group_by(&:difficulty)

    clusters.map do |difficulty, nodes|
      {
        cluster_id: "difficulty_#{difficulty}",
        cluster_type: 'difficulty',
        cluster_name: difficulty_label(difficulty),
        difficulty: difficulty,
        concepts: nodes.map(&:to_graph_json),
        size: nodes.size
      }
    end.sort_by { |c| c[:difficulty] }
  end

  # Cluster concepts by frequency (how often they appear in questions)
  def cluster_by_frequency
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active

    clusters = {
      high: concepts.where('frequency >= ?', 10),
      medium: concepts.where('frequency >= ? AND frequency < ?', 5, 10),
      low: concepts.where('frequency < ?', 5)
    }

    clusters.map do |level, nodes|
      {
        cluster_id: "frequency_#{level}",
        cluster_type: 'frequency',
        cluster_name: "#{level.to_s.capitalize} Frequency",
        frequency_range: frequency_range(level),
        concepts: nodes.map(&:to_graph_json),
        size: nodes.count
      }
    end
  end

  # Cluster concepts by hierarchical structure
  def cluster_by_hierarchy
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active

    # Get all subjects
    subjects = concepts.by_level('subject')

    subjects.map do |subject|
      chapters = concepts.where(parent_name: subject.name, level: 'chapter')

      chapter_clusters = chapters.map do |chapter|
        chapter_concepts = concepts.where(parent_name: chapter.name, level: 'concept')

        {
          chapter_id: chapter.id,
          chapter_name: chapter.name,
          concepts: chapter_concepts.map(&:to_graph_json),
          size: chapter_concepts.count
        }
      end

      {
        cluster_id: "subject_#{subject.id}",
        cluster_type: 'hierarchy',
        cluster_name: subject.name,
        subject_id: subject.id,
        chapters: chapter_clusters,
        total_concepts: chapter_clusters.sum { |c| c[:size] }
      }
    end
  end

  # Find concept gaps (concepts with low mastery across users)
  def identify_concept_gaps(user_ids = nil)
    concepts = KnowledgeNode.where(study_material_id: @study_material.id).active

    gap_analysis = concepts.map do |concept|
      masteries = if user_ids
                    concept.user_masteries.where(user_id: user_ids)
                  else
                    concept.user_masteries
                  end

      next if masteries.empty?

      avg_mastery = masteries.average(:mastery_level).to_f
      weak_count = masteries.where('mastery_level < ?', 0.5).count
      untested_count = masteries.where(status: 'untested').count

      {
        concept: concept.to_graph_json,
        avg_mastery: avg_mastery,
        weak_users: weak_count,
        untested_users: untested_count,
        total_users: masteries.count,
        gap_score: calculate_gap_score(avg_mastery, weak_count, masteries.count)
      }
    end.compact

    # Sort by gap score (highest = biggest gap)
    gap_analysis.sort_by { |g| -g[:gap_score] }
  end

  # Recommend related concepts for study
  def recommend_related_concepts(concept, limit: 5)
    related = []

    # 1. Prerequisites
    concept.prerequisites.each do |prereq|
      related << {
        concept: prereq.to_graph_json,
        relationship: 'prerequisite',
        priority: 10
      }
    end

    # 2. Same level concepts
    same_level = KnowledgeNode.where(
      study_material_id: @study_material.id,
      level: concept.level,
      parent_name: concept.parent_name
    ).where.not(id: concept.id).active.limit(3)

    same_level.each do |c|
      related << {
        concept: c.to_graph_json,
        relationship: 'same_level',
        priority: 5
      }
    end

    # 3. Related concepts by similarity
    similar = find_similar_concepts_by_embedding(concept, limit: 3)
    similar.each do |sim|
      related << {
        concept: sim[:concept].to_graph_json,
        relationship: 'similar',
        similarity_score: sim[:similarity],
        priority: 3
      }
    end

    # Sort by priority and return top N
    related.sort_by { |r| -r[:priority] }.first(limit)
  end

  private

  # Generate embeddings for concepts
  def generate_concept_embeddings(concepts)
    texts = concepts.map do |concept|
      "#{concept.name}: #{concept.description || ''}"
    end

    @openai_client.generate_batch_embeddings(texts)
  rescue StandardError => e
    Rails.logger.error("Embedding generation failed: #{e.message}")
    []
  end

  # Perform clustering using similarity threshold
  def perform_clustering(concepts, embeddings, threshold)
    return [] if embeddings.empty?

    clusters = []
    assigned = Set.new

    concepts.each_with_index do |concept, i|
      next if assigned.include?(i)

      cluster = [concept]
      assigned.add(i)

      # Find similar concepts
      concepts.each_with_index do |other_concept, j|
        next if i == j || assigned.include?(j)

        similarity = cosine_similarity(embeddings[i], embeddings[j])

        if similarity >= threshold
          cluster << other_concept
          assigned.add(j)
        end
      end

      clusters << {
        cluster_id: "cluster_#{clusters.size + 1}",
        cluster_type: 'similarity',
        representative: cluster.first.name,
        concepts: cluster.map(&:to_graph_json),
        size: cluster.size,
        avg_difficulty: (cluster.sum(&:difficulty).to_f / cluster.size).round(2)
      }
    end

    clusters
  end

  # Create cluster metadata
  def create_cluster_metadata(clusters)
    clusters.each do |cluster|
      concept_ids = cluster[:concepts].map { |c| c[:id] }

      # Update metadata for concepts in cluster
      KnowledgeNode.where(id: concept_ids).update_all(
        metadata: Arel.sql("json_set(metadata, '$.cluster_id', '#{cluster[:cluster_id]}')")
      )
    end
  rescue StandardError => e
    Rails.logger.error("Failed to create cluster metadata: #{e.message}")
  end

  # Calculate gap score
  def calculate_gap_score(avg_mastery, weak_count, total_count)
    return 0 if total_count.zero?

    # Lower mastery = higher gap
    mastery_gap = 1.0 - avg_mastery

    # More weak users = higher gap
    weak_ratio = weak_count.to_f / total_count

    # Weighted score
    (mastery_gap * 0.6) + (weak_ratio * 0.4)
  end

  # Find similar concepts by embedding
  def find_similar_concepts_by_embedding(concept, limit: 5)
    return [] unless concept.description.present?

    concept_embedding = @openai_client.generate_embedding(
      "#{concept.name}: #{concept.description}"
    )

    other_concepts = KnowledgeNode.where(study_material_id: @study_material.id)
                                   .where.not(id: concept.id)
                                   .where.not(description: nil)
                                   .active

    similarities = []

    other_concepts.find_each do |other|
      other_embedding = @openai_client.generate_embedding(
        "#{other.name}: #{other.description}"
      )

      similarity = cosine_similarity(concept_embedding, other_embedding)
      similarities << { concept: other, similarity: similarity }
    end

    similarities.sort_by { |s| -s[:similarity] }.first(limit)
  rescue StandardError => e
    Rails.logger.error("Similarity search failed: #{e.message}")
    []
  end

  # Calculate cosine similarity
  def cosine_similarity(vec1, vec2)
    return 0.0 if vec1.size != vec2.size

    dot_product = vec1.zip(vec2).map { |a, b| a * b }.sum
    magnitude1 = Math.sqrt(vec1.map { |x| x**2 }.sum)
    magnitude2 = Math.sqrt(vec2.map { |x| x**2 }.sum)

    return 0.0 if magnitude1.zero? || magnitude2.zero?

    dot_product / (magnitude1 * magnitude2)
  end

  # Get difficulty label
  def difficulty_label(difficulty)
    case difficulty
    when 1 then 'Very Easy'
    when 2 then 'Easy'
    when 3 then 'Medium'
    when 4 then 'Hard'
    when 5 then 'Very Hard'
    else 'Unknown'
    end
  end

  # Get frequency range
  def frequency_range(level)
    case level
    when :high then '10+'
    when :medium then '5-9'
    when :low then '0-4'
    else 'Unknown'
    end
  end
end
