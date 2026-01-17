# app/services/learning_path_optimizer.rb
class LearningPathOptimizer
  attr_reader :user, :study_set

  def initialize(user, study_set)
    @user = user
    @study_set = study_set
  end

  # Generate optimized learning path
  def generate_optimal_path
    # Get user's current mastery state
    mastery_state = analyze_mastery_state

    # Build dependency graph
    dependency_graph = build_dependency_graph

    # Calculate optimal learning sequence
    learning_sequence = calculate_optimal_sequence(dependency_graph, mastery_state)

    # Estimate time and difficulty
    enriched_path = enrich_with_metadata(learning_sequence, mastery_state)

    {
      user_id: user.id,
      study_set_id: study_set.id,
      current_level: mastery_state[:level],
      total_concepts: mastery_state[:total],
      mastered_concepts: mastery_state[:mastered],
      learning_sequence: enriched_path,
      estimated_total_hours: enriched_path.sum { |step| step[:estimated_hours] },
      completion_percentage: calculate_completion_percentage(mastery_state),
      next_milestone: identify_next_milestone(enriched_path)
    }
  end

  # Prioritize concepts based on urgency and importance
  def prioritize_concepts(exam_date: nil)
    concepts = get_all_concepts
    mastery_levels = get_mastery_levels

    prioritized = concepts.map do |concept|
      priority_score = calculate_priority_score(
        concept,
        mastery_levels[concept.id],
        exam_date
      )

      {
        concept_id: concept.id,
        concept_name: concept.name,
        priority_score: priority_score,
        mastery_level: mastery_levels[concept.id] || 0.0,
        urgency: calculate_urgency(concept, exam_date),
        importance: calculate_importance(concept),
        estimated_hours: estimate_learning_time(concept, mastery_levels[concept.id])
      }
    end

    prioritized.sort_by { |c| -c[:priority_score] }
  end

  # Generate personalized study schedule
  def generate_study_schedule(
    available_hours_per_day:,
    target_date: nil,
    preferred_session_length: 2
  )
    # Get prioritized concepts
    prioritized_concepts = prioritize_concepts(exam_date: target_date)

    # Calculate total hours needed
    total_hours_needed = prioritized_concepts.sum { |c| c[:estimated_hours] }

    # Calculate available days
    days_available = if target_date
                      [(target_date.to_date - Date.current).to_i, 1].max
                    else
                      (total_hours_needed / available_hours_per_day).ceil
                    end

    # Create daily schedule
    schedule = []
    current_day = 0
    remaining_hours_today = available_hours_per_day

    prioritized_concepts.each do |concept|
      hours_needed = concept[:estimated_hours]

      while hours_needed > 0
        if remaining_hours_today <= 0
          current_day += 1
          remaining_hours_today = available_hours_per_day
          break if current_day >= days_available
        end

        session_hours = [hours_needed, remaining_hours_today, preferred_session_length].min

        schedule << {
          day: current_day + 1,
          date: Date.current + current_day.days,
          concept_id: concept[:concept_id],
          concept_name: concept[:concept_name],
          session_hours: session_hours,
          priority: concept[:priority_score],
          session_type: determine_session_type(concept[:mastery_level])
        }

        hours_needed -= session_hours
        remaining_hours_today -= session_hours
      end

      break if current_day >= days_available
    end

    {
      schedule: schedule,
      total_days: schedule.map { |s| s[:day] }.max || 0,
      total_hours: schedule.sum { |s| s[:session_hours] },
      concepts_covered: schedule.map { |s| s[:concept_id] }.uniq.size,
      completion_feasibility: calculate_feasibility(total_hours_needed, days_available, available_hours_per_day)
    }
  end

  # Optimize learning order based on dependencies and difficulty
  def optimize_learning_order(concepts)
    # Build dependency graph for given concepts
    graph = build_subgraph(concepts)

    # Topological sort with difficulty consideration
    sorted = topological_sort_with_difficulty(graph)

    # Apply additional optimizations
    optimized = apply_chunking_strategy(sorted)

    optimized.map.with_index do |concept_id, index|
      {
        sequence_number: index + 1,
        concept_id: concept_id,
        concept_name: KnowledgeNode.find(concept_id).name,
        prerequisites: graph[concept_id][:prerequisites],
        difficulty_level: graph[concept_id][:difficulty]
      }
    end
  end

  # Suggest next best concept to study
  def suggest_next_concept
    # Get current mastery state
    mastery_state = analyze_mastery_state

    # Get concepts ready to learn (prerequisites met)
    ready_concepts = find_ready_concepts(mastery_state)

    return nil if ready_concepts.empty?

    # Score and rank
    scored_concepts = ready_concepts.map do |concept|
      {
        concept_id: concept.id,
        concept_name: concept.name,
        readiness_score: calculate_readiness_score(concept, mastery_state),
        estimated_hours: estimate_learning_time(concept, 0.0),
        prerequisites_mastered: count_prerequisites_mastered(concept, mastery_state)
      }
    end

    scored_concepts.sort_by { |c| -c[:readiness_score] }.first
  end

  private

  # Analyze current mastery state
  def analyze_mastery_state
    material_ids = study_set.study_materials.pluck(:id)
    all_concepts = KnowledgeNode.where(study_material_id: material_ids)

    masteries = user.user_masteries.joins(:knowledge_node)
                   .where(knowledge_nodes: { study_material_id: material_ids })

    {
      total: all_concepts.count,
      mastered: masteries.where(status: 'mastered').count,
      learning: masteries.where(status: 'learning').count,
      weak: masteries.where(status: 'weak').count,
      untested: all_concepts.count - masteries.count,
      level: calculate_level(masteries),
      mastery_map: masteries.pluck(:knowledge_node_id, :mastery_level).to_h
    }
  end

  # Build dependency graph from knowledge edges
  def build_dependency_graph
    material_ids = study_set.study_materials.pluck(:id)
    concepts = KnowledgeNode.where(study_material_id: material_ids)

    graph = {}

    concepts.each do |concept|
      prerequisites = KnowledgeEdge.where(related_node_id: concept.id, relationship_type: 'prerequisite')
                                  .pluck(:knowledge_node_id)

      dependents = KnowledgeEdge.where(knowledge_node_id: concept.id, relationship_type: 'prerequisite')
                                .pluck(:related_node_id)

      graph[concept.id] = {
        name: concept.name,
        prerequisites: prerequisites,
        dependents: dependents,
        difficulty: estimate_concept_difficulty(concept)
      }
    end

    graph
  end

  # Calculate optimal learning sequence using topological sort
  def calculate_optimal_sequence(graph, mastery_state)
    # Separate concepts by mastery status
    mastered = mastery_state[:mastery_map].select { |_, level| level >= 0.8 }.keys
    in_progress = mastery_state[:mastery_map].select { |_, level| level >= 0.4 && level < 0.8 }.keys
    weak = mastery_state[:mastery_map].select { |_, level| level < 0.4 }.keys
    untested = graph.keys - mastery_state[:mastery_map].keys

    sequence = []

    # Phase 1: Fix weak concepts
    if weak.any?
      weak_sorted = sort_by_dependencies(weak, graph)
      sequence.concat(weak_sorted.map { |cid| { concept_id: cid, phase: 'remedial', priority: 'high' } })
    end

    # Phase 2: Complete in-progress concepts
    if in_progress.any?
      progress_sorted = sort_by_dependencies(in_progress, graph)
      sequence.concat(progress_sorted.map { |cid| { concept_id: cid, phase: 'consolidation', priority: 'medium' } })
    end

    # Phase 3: Learn new concepts
    if untested.any?
      new_sorted = sort_by_dependencies(untested, graph)
      sequence.concat(new_sorted.map { |cid| { concept_id: cid, phase: 'acquisition', priority: 'medium' } })
    end

    sequence
  end

  # Sort concepts respecting dependencies
  def sort_by_dependencies(concept_ids, graph)
    # Khan's algorithm for topological sort
    in_degree = Hash.new(0)
    concept_ids.each do |cid|
      graph[cid][:prerequisites].each { |prereq| in_degree[cid] += 1 if concept_ids.include?(prereq) }
    end

    queue = concept_ids.select { |cid| in_degree[cid].zero? }
    result = []

    while queue.any?
      # Pick concept with lowest difficulty first
      current = queue.min_by { |cid| graph[cid][:difficulty] }
      queue.delete(current)
      result << current

      # Update dependents
      graph[current][:dependents].each do |dependent|
        next unless concept_ids.include?(dependent)
        in_degree[dependent] -= 1
        queue << dependent if in_degree[dependent].zero?
      end
    end

    # Handle cycles (shouldn't happen but defensive)
    remaining = concept_ids - result
    result.concat(remaining.sort_by { |cid| graph[cid][:difficulty] })

    result
  end

  # Enrich learning sequence with metadata
  def enrich_with_metadata(sequence, mastery_state)
    sequence.map do |step|
      concept_id = step[:concept_id]
      concept = KnowledgeNode.find(concept_id)
      current_mastery = mastery_state[:mastery_map][concept_id] || 0.0

      step.merge(
        concept_name: concept.name,
        current_mastery: current_mastery,
        target_mastery: 0.8,
        estimated_hours: estimate_learning_time(concept, current_mastery),
        question_count: estimate_question_count(concept),
        difficulty_level: estimate_concept_difficulty(concept)
      )
    end
  end

  # Calculate completion percentage
  def calculate_completion_percentage(mastery_state)
    return 0.0 if mastery_state[:total].zero?

    (mastery_state[:mastered].to_f / mastery_state[:total] * 100).round(2)
  end

  # Identify next milestone
  def identify_next_milestone(learning_path)
    # Find the first high-priority item not yet mastered
    next_critical = learning_path.find { |step| step[:priority] == 'high' }

    return nil unless next_critical

    {
      concept_id: next_critical[:concept_id],
      concept_name: next_critical[:concept_name],
      phase: next_critical[:phase],
      estimated_hours: next_critical[:estimated_hours]
    }
  end

  # Get all concepts for study set
  def get_all_concepts
    material_ids = study_set.study_materials.pluck(:id)
    KnowledgeNode.where(study_material_id: material_ids)
  end

  # Get mastery levels
  def get_mastery_levels
    user.user_masteries.pluck(:knowledge_node_id, :mastery_level).to_h
  end

  # Calculate priority score
  def calculate_priority_score(concept, mastery_level, exam_date)
    urgency_score = calculate_urgency(concept, exam_date)
    importance_score = calculate_importance(concept)
    weakness_score = mastery_level ? (1.0 - mastery_level) * 50 : 30

    (urgency_score * 0.3 + importance_score * 0.4 + weakness_score * 0.3).round(2)
  end

  # Calculate urgency based on exam date
  def calculate_urgency(concept, exam_date)
    return 50.0 unless exam_date

    days_until_exam = (exam_date.to_date - Date.current).to_i
    return 100.0 if days_until_exam <= 7
    return 80.0 if days_until_exam <= 30
    return 60.0 if days_until_exam <= 60

    40.0
  end

  # Calculate importance based on concept centrality
  def calculate_importance(concept)
    # Count how many other concepts depend on this
    dependents_count = KnowledgeEdge.where(knowledge_node_id: concept.id, relationship_type: 'prerequisite').count

    # Count questions related to this concept
    questions_count = QuestionConcept.where(knowledge_node_id: concept.id).count

    importance = (dependents_count * 10 + questions_count * 2).to_f
    [importance, 100.0].min
  end

  # Estimate learning time for a concept
  def estimate_learning_time(concept, current_mastery)
    base_hours = 2.0
    difficulty_multiplier = estimate_concept_difficulty(concept) / 5.0
    mastery_gap = 1.0 - (current_mastery || 0.0)

    (base_hours * difficulty_multiplier * mastery_gap).round(1)
  end

  # Estimate concept difficulty
  def estimate_concept_difficulty(concept)
    # Based on prerequisites count and question difficulty
    prerequisites_count = KnowledgeEdge.where(related_node_id: concept.id, relationship_type: 'prerequisite').count

    case prerequisites_count
    when 0..1 then 2
    when 2..3 then 3
    when 4..5 then 4
    else 5
    end
  end

  # Estimate question count for concept
  def estimate_question_count(concept)
    QuestionConcept.where(knowledge_node_id: concept.id).count
  end

  # Calculate user level
  def calculate_level(masteries)
    return 'beginner' if masteries.empty?

    mastered_percentage = (masteries.where(status: 'mastered').count.to_f / masteries.count * 100)

    case mastered_percentage
    when 0...25 then 'beginner'
    when 25...50 then 'intermediate'
    when 50...75 then 'advanced'
    else 'expert'
    end
  end

  # Determine session type based on mastery
  def determine_session_type(mastery_level)
    case mastery_level
    when 0.0...0.4 then 'learning'
    when 0.4...0.8 then 'practice'
    else 'review'
    end
  end

  # Calculate feasibility of completing study plan
  def calculate_feasibility(hours_needed, days_available, hours_per_day)
    total_hours_available = days_available * hours_per_day
    ratio = hours_needed.to_f / total_hours_available

    case ratio
    when 0.0...0.8 then 'feasible'
    when 0.8...1.2 then 'tight'
    else 'challenging'
    end
  end

  # Build subgraph for specific concepts
  def build_subgraph(concepts)
    concept_ids = concepts.map(&:id)
    graph = {}

    concepts.each do |concept|
      prerequisites = KnowledgeEdge.where(related_node_id: concept.id, relationship_type: 'prerequisite')
                                  .where(knowledge_node_id: concept_ids)
                                  .pluck(:knowledge_node_id)

      graph[concept.id] = {
        name: concept.name,
        prerequisites: prerequisites,
        difficulty: estimate_concept_difficulty(concept)
      }
    end

    graph
  end

  # Topological sort with difficulty consideration
  def topological_sort_with_difficulty(graph)
    sort_by_dependencies(graph.keys, graph)
  end

  # Apply chunking strategy for better learning
  def apply_chunking_strategy(sorted_concepts)
    # Group related concepts together
    chunks = []
    current_chunk = []

    sorted_concepts.each do |concept_id|
      if current_chunk.size >= 3
        chunks << current_chunk
        current_chunk = [concept_id]
      else
        current_chunk << concept_id
      end
    end

    chunks << current_chunk if current_chunk.any?
    chunks.flatten
  end

  # Find concepts ready to learn
  def find_ready_concepts(mastery_state)
    material_ids = study_set.study_materials.pluck(:id)
    all_concepts = KnowledgeNode.where(study_material_id: material_ids)
    mastered_ids = mastery_state[:mastery_map].select { |_, level| level >= 0.8 }.keys

    ready = all_concepts.select do |concept|
      # Not yet mastered
      next false if mastered_ids.include?(concept.id)

      # Prerequisites met
      prerequisites = KnowledgeEdge.where(related_node_id: concept.id, relationship_type: 'prerequisite')
                                  .pluck(:knowledge_node_id)

      prerequisites.empty? || (prerequisites - mastered_ids).empty?
    end

    ready
  end

  # Calculate readiness score
  def calculate_readiness_score(concept, mastery_state)
    prerequisites_count = count_prerequisites_mastered(concept, mastery_state)
    importance = calculate_importance(concept)
    current_mastery = mastery_state[:mastery_map][concept.id] || 0.0

    (prerequisites_count * 10 + importance * 0.5 + current_mastery * 20).round(2)
  end

  # Count mastered prerequisites
  def count_prerequisites_mastered(concept, mastery_state)
    prerequisites = KnowledgeEdge.where(related_node_id: concept.id, relationship_type: 'prerequisite')
                                .pluck(:knowledge_node_id)

    return 0 if prerequisites.empty?

    mastered_ids = mastery_state[:mastery_map].select { |_, level| level >= 0.8 }.keys
    (prerequisites & mastered_ids).size
  end
end
