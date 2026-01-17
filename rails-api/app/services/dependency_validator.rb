class DependencyValidator
  attr_reader :errors, :warnings

  def initialize
    @errors = []
    @warnings = []
  end

  # Validate a single prerequisite relationship
  def validate_relationship(source_node, target_node)
    reset_validation_state

    return false unless nodes_exist?(source_node, target_node)
    return false if self_reference?(source_node, target_node)
    return false if creates_cycle?(source_node, target_node)

    check_depth_limit(source_node, target_node)
    check_difficulty_order(source_node, target_node)

    @errors.empty?
  end

  # Validate an entire learning path
  def valid_path?(nodes)
    reset_validation_state

    return add_error("Path is empty") if nodes.empty?
    return add_error("Path has duplicate nodes") if has_duplicates?(nodes)

    # Check each consecutive pair
    nodes.each_cons(2) do |current, next_node|
      unless valid_transition?(current, next_node)
        return false
      end
    end

    true
  end

  # Detect circular dependencies in the entire graph
  def detect_circular_dependencies(study_material)
    reset_validation_state
    cycles = []

    study_material.knowledge_nodes.active.each do |node|
      path = []
      visited = Set.new

      if has_cycle?(node, path, visited)
        cycles << path.map(&:id)
      end
    end

    cycles.uniq
  end

  # Check if adding a relationship would create a cycle
  def creates_cycle?(source_node, target_node)
    # If target can reach source, adding edge from source to target creates a cycle
    if can_reach?(target_node, source_node)
      add_error("Adding this relationship would create a circular dependency: " \
                "#{source_node.name} -> #{target_node.name} -> ... -> #{source_node.name}")
      return true
    end

    false
  end

  # Validate depth limits
  def check_depth_limit(source_node, target_node, max_depth = 10)
    current_depth = calculate_node_depth(source_node)

    if current_depth >= max_depth
      add_warning("Node #{source_node.name} is already at depth #{current_depth}. " \
                  "Adding more prerequisites may make the graph too complex.")
    end
  end

  # Check difficulty ordering
  def check_difficulty_order(prerequisite, dependent)
    if prerequisite.difficulty > dependent.difficulty
      add_warning("Prerequisite '#{prerequisite.name}' (difficulty #{prerequisite.difficulty}) " \
                  "is harder than dependent '#{dependent.name}' (difficulty #{dependent.difficulty}). " \
                  "Consider reviewing the difficulty levels.")
    end
  end

  # Validate entire knowledge graph
  def validate_graph(study_material)
    reset_validation_state

    nodes = study_material.knowledge_nodes.active
    edges = KnowledgeEdge.where(knowledge_node: nodes)

    # Check for cycles
    cycles = detect_circular_dependencies(study_material)
    if cycles.any?
      add_error("Found #{cycles.size} circular dependencies in the graph")
    end

    # Check for orphaned nodes
    orphaned = find_orphaned_nodes(nodes)
    if orphaned.any?
      add_warning("Found #{orphaned.size} orphaned nodes (no connections)")
    end

    # Check for excessive depth
    deep_nodes = find_deep_nodes(nodes)
    if deep_nodes.any?
      add_warning("Found #{deep_nodes.size} nodes with depth > 5")
    end

    # Check for missing strength classifications
    unclassified = edges.where(strength: nil).count
    if unclassified > 0
      add_warning("#{unclassified} edges lack strength classification")
    end

    {
      valid: @errors.empty?,
      errors: @errors,
      warnings: @warnings,
      statistics: {
        total_nodes: nodes.count,
        total_edges: edges.count,
        cycles_found: cycles.size,
        orphaned_nodes: orphaned.size,
        deep_nodes: deep_nodes.size,
        unclassified_edges: unclassified
      }
    }
  end

  # Fix circular dependencies automatically
  def fix_circular_dependencies(study_material)
    cycles = detect_circular_dependencies(study_material)
    fixed = []

    cycles.each do |cycle_ids|
      # Remove the weakest edge in the cycle
      edges = find_cycle_edges(cycle_ids)
      weakest_edge = edges.min_by { |e| e.weight || 0.5 }

      if weakest_edge
        weakest_edge.update(active: false)
        fixed << {
          removed_edge: weakest_edge.id,
          from: weakest_edge.knowledge_node.name,
          to: weakest_edge.related_node.name,
          reason: "Weakest link in circular dependency"
        }
      end
    end

    fixed
  end

  # Check prerequisite consistency
  def check_consistency(node)
    issues = []

    # Check if all prerequisites are from the same study material
    external_prereqs = node.prerequisites.where.not(study_material_id: node.study_material_id)
    if external_prereqs.any?
      issues << {
        type: 'external_prerequisites',
        message: "Node has prerequisites from different study materials",
        count: external_prereqs.count
      }
    end

    # Check for duplicate relationships
    duplicate_edges = node.outgoing_edges
      .group(:related_node_id, :relationship_type)
      .having('COUNT(*) > 1')
      .count

    if duplicate_edges.any?
      issues << {
        type: 'duplicate_relationships',
        message: "Node has duplicate relationship definitions",
        count: duplicate_edges.size
      }
    end

    # Check for contradictory relationships
    node.prerequisites.each do |prereq|
      if prereq.prerequisites.include?(node)
        issues << {
          type: 'mutual_prerequisites',
          message: "Mutual prerequisite relationship with #{prereq.name}",
          node_id: prereq.id
        }
      end
    end

    issues
  end

  # Calculate dependency health score
  def calculate_health_score(study_material)
    validation = validate_graph(study_material)

    # Start with perfect score
    score = 100.0

    # Deduct points for issues
    score -= validation[:statistics][:cycles_found] * 20
    score -= validation[:statistics][:orphaned_nodes] * 2
    score -= validation[:statistics][:deep_nodes] * 5
    score -= @warnings.size * 1

    [0, score].max.round(2)
  end

  private

  def reset_validation_state
    @errors = []
    @warnings = []
  end

  def nodes_exist?(source, target)
    unless source && target
      add_error("Source or target node is nil")
      return false
    end
    true
  end

  def self_reference?(source, target)
    if source.id == target.id
      add_error("Node cannot be its own prerequisite")
      return true
    end
    false
  end

  def has_duplicates?(nodes)
    nodes.size != nodes.map(&:id).uniq.size
  end

  def valid_transition?(from_node, to_node)
    # Check if there's a prerequisite relationship
    edge = KnowledgeEdge.find_by(
      knowledge_node_id: from_node.id,
      related_node_id: to_node.id,
      relationship_type: 'prerequisite',
      active: true
    )

    unless edge
      add_warning("No prerequisite relationship found between #{from_node.name} and #{to_node.name}")
    end

    true # Don't fail, just warn
  end

  def has_cycle?(node, path, visited)
    return false if visited.include?(node.id)

    if path.map(&:id).include?(node.id)
      path << node
      return true
    end

    visited.add(node.id)
    path << node

    node.prerequisites.each do |prereq|
      if has_cycle?(prereq, path.dup, visited.dup)
        return true
      end
    end

    false
  end

  def can_reach?(from_node, to_node, visited = Set.new)
    return false if visited.include?(from_node.id)
    return true if from_node.id == to_node.id

    visited.add(from_node.id)

    from_node.prerequisites.any? do |prereq|
      can_reach?(prereq, to_node, visited)
    end
  end

  def calculate_node_depth(node, visited = Set.new)
    return 0 if visited.include?(node.id)

    visited.add(node.id)
    prerequisites = node.prerequisites

    return 0 if prerequisites.empty?

    max_prereq_depth = prerequisites.map { |p| calculate_node_depth(p, visited.dup) }.max || 0
    max_prereq_depth + 1
  end

  def find_orphaned_nodes(nodes)
    nodes.select do |node|
      node.outgoing_edges.where(relationship_type: 'prerequisite').empty? &&
        node.incoming_edges.where(relationship_type: 'prerequisite').empty?
    end
  end

  def find_deep_nodes(nodes, max_depth = 5)
    nodes.select { |node| calculate_node_depth(node) > max_depth }
  end

  def find_cycle_edges(cycle_ids)
    edges = []

    cycle_ids.each_with_index do |node_id, i|
      next_id = cycle_ids[(i + 1) % cycle_ids.size]

      edge = KnowledgeEdge.find_by(
        knowledge_node_id: node_id,
        related_node_id: next_id,
        relationship_type: 'prerequisite'
      )

      edges << edge if edge
    end

    edges
  end

  def add_error(message)
    @errors << message
    false
  end

  def add_warning(message)
    @warnings << message
    true
  end
end
