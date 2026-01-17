class LearningPathService
  def initialize(user, study_material)
    @user = user
    @study_material = study_material
    @validator = DependencyValidator.new
  end

  # Generate multiple learning path options
  def generate_paths(target_node, options = {})
    paths = []

    # Option 1: Shortest path (BFS)
    paths << generate_shortest_path(target_node)

    # Option 2: Comprehensive path (all prerequisites)
    paths << generate_comprehensive_path(target_node)

    # Option 3: Beginner-friendly path (sorted by difficulty)
    paths << generate_beginner_friendly_path(target_node)

    # Option 4: Adaptive path (based on current mastery)
    paths << generate_adaptive_path(target_node)

    # Filter out nil paths and validate
    paths.compact.select { |path| @validator.valid_path?(path[:nodes]) }
  end

  # Generate shortest learning path using BFS
  def generate_shortest_path(target_node)
    return nil unless target_node

    visited = Set.new
    queue = [[target_node]]
    path_found = nil

    while queue.any? && path_found.nil?
      current_path = queue.shift
      current_node = current_path.last

      if all_prerequisites_mastered?(current_node)
        path_found = current_path
        break
      end

      current_node.prerequisites.each do |prereq|
        next if visited.include?(prereq.id)

        visited.add(prereq.id)
        new_path = current_path + [prereq]
        queue << new_path
      end
    end

    return nil unless path_found

    # Reverse to get learning order
    nodes = path_found.reverse.uniq

    create_learning_path(
      nodes: nodes,
      target_node: target_node,
      path_type: 'shortest',
      path_name: "Shortest Path to #{target_node.name}"
    )
  end

  # Generate comprehensive path covering all prerequisites
  def generate_comprehensive_path(target_node)
    return nil unless target_node

    all_prereqs = target_node.all_prerequisites
    nodes = topological_sort(all_prereqs + [target_node])

    return nil if nodes.empty?

    create_learning_path(
      nodes: nodes,
      target_node: target_node,
      path_type: 'comprehensive',
      path_name: "Comprehensive Path to #{target_node.name}",
      description: "Complete mastery of all prerequisite concepts"
    )
  end

  # Generate beginner-friendly path (sorted by difficulty)
  def generate_beginner_friendly_path(target_node)
    return nil unless target_node

    all_prereqs = target_node.all_prerequisites

    # Sort by difficulty, then by importance
    nodes = (all_prereqs + [target_node]).sort_by do |node|
      [node.difficulty, -node.importance]
    end

    # Ensure prerequisite order is maintained
    nodes = ensure_prerequisite_order(nodes)

    create_learning_path(
      nodes: nodes,
      target_node: target_node,
      path_type: 'beginner_friendly',
      path_name: "Beginner-Friendly Path to #{target_node.name}",
      description: "Gradual progression from easier to harder concepts"
    )
  end

  # Generate adaptive path based on user's current mastery
  def generate_adaptive_path(target_node)
    return nil unless target_node

    all_prereqs = target_node.all_prerequisites

    # Filter out already mastered concepts
    unmastered = all_prereqs.select do |node|
      mastery = get_user_mastery(node)
      mastery < 0.8
    end

    # Add target node if not mastered
    target_mastery = get_user_mastery(target_node)
    unmastered << target_node if target_mastery < 0.8

    return nil if unmastered.empty?

    # Sort by mastery level (practice weaker concepts first)
    nodes = unmastered.sort_by do |node|
      [get_user_mastery(node), node.difficulty]
    end

    # Ensure prerequisite order
    nodes = ensure_prerequisite_order(nodes)

    create_learning_path(
      nodes: nodes,
      target_node: target_node,
      path_type: 'adaptive',
      path_name: "Personalized Path to #{target_node.name}",
      description: "Customized based on your current mastery levels"
    )
  end

  # Generate custom path with specific options
  def generate_custom_path(target_node, options = {})
    max_nodes = options[:max_nodes] || 10
    focus_areas = options[:focus_areas] || []
    skip_mastered = options[:skip_mastered] != false

    all_prereqs = target_node.all_prerequisites

    # Filter by focus areas if specified
    if focus_areas.any?
      all_prereqs = all_prereqs.select { |n| focus_areas.include?(n.level) }
    end

    # Skip mastered concepts if requested
    if skip_mastered
      all_prereqs = all_prereqs.reject { |n| get_user_mastery(n) >= 0.8 }
    end

    # Limit number of nodes
    nodes = all_prereqs.take(max_nodes)
    nodes = topological_sort(nodes + [target_node])

    create_learning_path(
      nodes: nodes,
      target_node: target_node,
      path_type: 'custom',
      path_name: options[:name] || "Custom Path to #{target_node.name}",
      description: options[:description]
    )
  end

  # Calculate optimal learning sequence using topological sort
  def topological_sort(nodes)
    return [] if nodes.empty?

    # Build adjacency list
    graph = {}
    in_degree = {}

    nodes.each do |node|
      graph[node.id] = []
      in_degree[node.id] = 0
    end

    # Build edges
    nodes.each do |node|
      prereqs = node.prerequisites & nodes
      prereqs.each do |prereq|
        graph[prereq.id] << node.id
        in_degree[node.id] += 1
      end
    end

    # Kahn's algorithm
    queue = nodes.select { |n| in_degree[n.id] == 0 }
    sorted = []

    while queue.any?
      current = queue.shift
      sorted << current

      next unless graph[current.id]

      graph[current.id].each do |neighbor_id|
        in_degree[neighbor_id] -= 1
        if in_degree[neighbor_id] == 0
          neighbor = nodes.find { |n| n.id == neighbor_id }
          queue << neighbor if neighbor
        end
      end
    end

    # Return sorted nodes or empty if cycle detected
    sorted.size == nodes.size ? sorted : []
  end

  # Update existing path progress
  def update_path_progress(path, node_id)
    return unless path && node_id

    path.mark_node_completed(node_id)
    path.last_activity_at = Time.current
    path.actual_hours = calculate_actual_hours(path)
    path.path_score = path.calculate_path_score
    path.save!

    # Check if we should recommend next step
    if path.completed?
      suggest_next_goals(path)
    end

    path
  end

  # Suggest next learning goals after completing a path
  def suggest_next_goals(completed_path)
    target = completed_path.target_node
    return [] unless target

    # Find nodes that depend on the target
    next_concepts = target.dependents
      .select { |n| get_user_mastery(n) < 0.8 }
      .sort_by { |n| [-n.importance, n.difficulty] }
      .take(5)

    next_concepts.map do |concept|
      {
        node_id: concept.id,
        node_name: concept.name,
        difficulty: concept.difficulty,
        importance: concept.importance,
        current_mastery: get_user_mastery(concept),
        estimated_hours: estimate_learning_hours(concept)
      }
    end
  end

  # Compare multiple paths and rank them
  def rank_paths(paths)
    paths.map do |path|
      score = calculate_path_ranking_score(path)
      path.merge(ranking_score: score)
    end.sort_by { |p| -p[:ranking_score] }
  end

  # Estimate learning time for a path
  def estimate_path_duration(nodes)
    nodes.sum { |node| estimate_learning_hours(node) }
  end

  # Get alternative paths if current path is too difficult
  def get_alternative_paths(current_path)
    return [] unless current_path.target_node

    all_paths = generate_paths(current_path.target_node)

    # Exclude current path and filter by different criteria
    alternatives = all_paths.reject { |p| p[:path_type] == current_path.path_type }

    # Rank by suitability
    rank_paths(alternatives).take(3)
  end

  private

  def create_learning_path(nodes:, target_node:, path_type:, path_name:, description: nil)
    return nil if nodes.empty?

    edges = extract_edges(nodes)
    estimated_hours = estimate_path_duration(nodes)

    path_data = {
      nodes: nodes.map(&:id),
      edges: edges.map(&:id),
      total_nodes: nodes.size,
      difficulty_level: calculate_path_difficulty(nodes),
      estimated_hours: estimated_hours
    }

    # Return path data (not yet persisted)
    {
      path_type: path_type,
      path_name: path_name,
      description: description,
      node_sequence: nodes.map(&:id),
      edge_sequence: edges.map(&:id),
      total_nodes: nodes.size,
      difficulty_level: calculate_path_difficulty(nodes),
      estimated_hours: estimated_hours,
      priority: calculate_path_priority(nodes, target_node),
      nodes: nodes,
      edges: edges
    }
  end

  def extract_edges(nodes)
    edges = []

    nodes.each_with_index do |node, i|
      next if i == nodes.size - 1

      next_node = nodes[i + 1]
      edge = KnowledgeEdge.find_by(
        knowledge_node_id: node.id,
        related_node_id: next_node.id,
        relationship_type: 'prerequisite'
      )

      edges << edge if edge
    end

    edges
  end

  def calculate_path_difficulty(nodes)
    return 3 if nodes.empty?

    avg_difficulty = nodes.sum(&:difficulty).to_f / nodes.size
    avg_difficulty.round
  end

  def calculate_path_priority(nodes, target_node)
    # Higher priority for important concepts with low mastery
    target_importance = target_node.importance
    avg_mastery = nodes.map { |n| get_user_mastery(n) }.sum / nodes.size

    priority = target_importance * (1 - avg_mastery)
    [1, [priority * 10, 10].min].max.round
  end

  def ensure_prerequisite_order(nodes)
    sorted = topological_sort(nodes)
    sorted.empty? ? nodes : sorted
  end

  def all_prerequisites_mastered?(node)
    node.prerequisites.all? { |prereq| get_user_mastery(prereq) >= 0.8 }
  end

  def get_user_mastery(node)
    mastery = UserMastery.find_by(user_id: @user.id, knowledge_node_id: node.id)
    mastery&.mastery_level || 0.0
  end

  def estimate_learning_hours(node)
    # Base hours by difficulty
    base_hours = case node.difficulty
    when 1 then 1
    when 2 then 2
    when 3 then 3
    when 4 then 5
    when 5 then 8
    else 3
    end

    # Adjust by current mastery
    current_mastery = get_user_mastery(node)
    remaining_factor = 1 - current_mastery

    (base_hours * remaining_factor).ceil
  end

  def calculate_actual_hours(path)
    return 0 unless path.started_at

    total_minutes = path.learning_statistics.dig('total_study_minutes') || 0
    (total_minutes / 60.0).round(1)
  end

  def calculate_path_ranking_score(path)
    factors = []

    # Factor 1: Fewer nodes is better (efficiency)
    node_efficiency = 1.0 / (1 + path[:total_nodes] / 10.0)
    factors << node_efficiency

    # Factor 2: Lower difficulty is better for beginners
    difficulty_score = 1.0 - (path[:difficulty_level] - 1) / 4.0
    factors << difficulty_score

    # Factor 3: Shorter estimated time
    time_efficiency = 1.0 / (1 + path[:estimated_hours] / 10.0)
    factors << time_efficiency

    # Factor 4: Higher priority paths
    priority_score = path[:priority] / 10.0
    factors << priority_score

    factors.sum / factors.size
  end
end
