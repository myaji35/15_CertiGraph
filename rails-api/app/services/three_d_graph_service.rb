class ThreeDGraphService
  attr_reader :study_material, :user

  # Constants for 3D layout
  SPHERE_RADIUS = 100
  FORCE_ITERATIONS = 100
  REPULSION_STRENGTH = 500
  ATTRACTION_STRENGTH = 0.01
  DAMPING = 0.9

  def initialize(study_material, user = nil)
    @study_material = study_material
    @user = user
  end

  # Generate 3D graph with force-directed layout
  def generate_3d_graph(nodes: nil)
    nodes ||= KnowledgeNode.where(study_material_id: study_material.id, active: true)
    edges = fetch_edges_for_nodes(nodes)

    # Initialize positions
    node_positions = initialize_positions(nodes)

    # Apply force-directed layout
    node_positions = apply_force_directed_layout(nodes, edges, node_positions)

    # Build JSON response
    build_graph_json(nodes, edges, node_positions)
  end

  # Initialize nodes with random positions on a sphere
  def initialize_positions(nodes)
    positions = {}

    nodes.each_with_index do |node, index|
      # Distribute nodes on a sphere using Fibonacci sphere algorithm
      positions[node.id] = fibonacci_sphere_point(index, nodes.count)
    end

    positions
  end

  # Fibonacci sphere algorithm for even distribution
  def fibonacci_sphere_point(index, total)
    phi = Math::PI * (3.0 - Math.sqrt(5.0))  # Golden angle in radians
    y = 1 - (index / (total - 1.0)) * 2      # y goes from 1 to -1
    radius = Math.sqrt(1 - y * y)            # radius at y

    theta = phi * index

    x = Math.cos(theta) * radius * SPHERE_RADIUS
    z = Math.sin(theta) * radius * SPHERE_RADIUS
    y = y * SPHERE_RADIUS

    { x: x.round(2), y: y.round(2), z: z.round(2) }
  end

  # Apply force-directed layout algorithm
  def apply_force_directed_layout(nodes, edges, positions)
    node_velocities = Hash.new { |h, k| h[k] = { x: 0, y: 0, z: 0 } }

    FORCE_ITERATIONS.times do |iteration|
      forces = Hash.new { |h, k| h[k] = { x: 0, y: 0, z: 0 } }

      # Calculate repulsion forces between all nodes
      nodes.each do |node1|
        nodes.each do |node2|
          next if node1.id == node2.id

          force = calculate_repulsion_force(
            positions[node1.id],
            positions[node2.id]
          )

          forces[node1.id][:x] += force[:x]
          forces[node1.id][:y] += force[:y]
          forces[node1.id][:z] += force[:z]
        end
      end

      # Calculate attraction forces for connected nodes
      edges.each do |edge|
        force = calculate_attraction_force(
          positions[edge.knowledge_node_id],
          positions[edge.related_node_id],
          edge.weight
        )

        # Apply Newton's third law
        forces[edge.knowledge_node_id][:x] += force[:x]
        forces[edge.knowledge_node_id][:y] += force[:y]
        forces[edge.knowledge_node_id][:z] += force[:z]

        forces[edge.related_node_id][:x] -= force[:x]
        forces[edge.related_node_id][:y] -= force[:y]
        forces[edge.related_node_id][:z] -= force[:z]
      end

      # Update velocities and positions
      nodes.each do |node|
        # Update velocity with damping
        node_velocities[node.id][:x] = (node_velocities[node.id][:x] + forces[node.id][:x]) * DAMPING
        node_velocities[node.id][:y] = (node_velocities[node.id][:y] + forces[node.id][:y]) * DAMPING
        node_velocities[node.id][:z] = (node_velocities[node.id][:z] + forces[node.id][:z]) * DAMPING

        # Update position
        positions[node.id][:x] += node_velocities[node.id][:x]
        positions[node.id][:y] += node_velocities[node.id][:y]
        positions[node.id][:z] += node_velocities[node.id][:z]

        # Round for cleaner JSON
        positions[node.id][:x] = positions[node.id][:x].round(2)
        positions[node.id][:y] = positions[node.id][:y].round(2)
        positions[node.id][:z] = positions[node.id][:z].round(2)
      end

      # Cool down the system (reduce movement over time)
      DAMPING * (1.0 - iteration.to_f / FORCE_ITERATIONS)
    end

    positions
  end

  # Calculate repulsion force between two nodes
  def calculate_repulsion_force(pos1, pos2)
    dx = pos1[:x] - pos2[:x]
    dy = pos1[:y] - pos2[:y]
    dz = pos1[:z] - pos2[:z]

    distance = Math.sqrt(dx**2 + dy**2 + dz**2)
    distance = [distance, 1.0].max  # Avoid division by zero

    force_magnitude = REPULSION_STRENGTH / (distance**2)

    # Normalize direction and apply magnitude
    {
      x: (dx / distance) * force_magnitude,
      y: (dy / distance) * force_magnitude,
      z: (dz / distance) * force_magnitude
    }
  end

  # Calculate attraction force between connected nodes
  def calculate_attraction_force(pos1, pos2, weight)
    dx = pos2[:x] - pos1[:x]
    dy = pos2[:y] - pos1[:y]
    dz = pos2[:z] - pos1[:z]

    distance = Math.sqrt(dx**2 + dy**2 + dz**2)

    # Spring force proportional to distance and edge weight
    force_magnitude = distance * ATTRACTION_STRENGTH * weight

    {
      x: dx * force_magnitude,
      y: dy * force_magnitude,
      z: dz * force_magnitude
    }
  end

  # Build final JSON response
  def build_graph_json(nodes, edges, positions)
    {
      nodes: nodes.map do |node|
        {
          id: node.id,
          name: node.name,
          level: node.level,
          description: node.description,
          difficulty: node.difficulty,
          importance: node.importance,
          color: calculate_node_color(node),
          mastery_level: calculate_mastery_level(node),
          position: positions[node.id],
          size: calculate_node_size(node),
          metadata: {
            parent_name: node.parent_name,
            active: node.active,
            prerequisites_count: node.prerequisites.count,
            dependents_count: node.dependents.count
          }
        }
      end,
      edges: edges.map do |edge|
        {
          id: edge.id,
          source: edge.knowledge_node_id,
          target: edge.related_node_id,
          relationship_type: edge.relationship_type,
          relationship_name: edge.relationship_name,
          weight: edge.weight,
          strength: calculate_edge_strength(edge),
          color: calculate_edge_color(edge),
          metadata: {
            reasoning: edge.reasoning,
            active: edge.active
          }
        }
      end,
      statistics: {
        total_nodes: nodes.count,
        total_edges: edges.count,
        avg_connections: nodes.count > 0 ? (edges.count.to_f / nodes.count).round(2) : 0
      }
    }
  end

  # Calculate node color based on mastery
  def calculate_node_color(node)
    return '#808080' unless user  # Gray for untested

    mastery = UserMastery.find_by(user: user, knowledge_node: node)
    return '#808080' unless mastery

    case mastery.color
    when 'green'
      '#00ff00'  # Green - mastered
    when 'yellow'
      '#ffff00'  # Yellow - learning
    when 'red'
      '#ff0000'  # Red - weak
    else
      '#808080'  # Gray - untested
    end
  end

  # Calculate mastery level
  def calculate_mastery_level(node)
    return 0.0 unless user

    mastery = UserMastery.find_by(user: user, knowledge_node: node)
    mastery ? mastery.mastery_level : 0.0
  end

  # Calculate node size based on importance and connections
  def calculate_node_size(node)
    base_size = 5.0
    importance_factor = node.importance * 0.5
    connection_count = node.outgoing_edges.count + node.incoming_edges.count
    connection_factor = Math.log(connection_count + 1) * 0.3

    (base_size + importance_factor + connection_factor).round(2)
  end

  # Calculate edge strength for visualization
  def calculate_edge_strength(edge)
    # Stronger relationships should be more visible
    case edge.relationship_type
    when 'prerequisite'
      edge.weight * 1.2
    when 'part_of'
      edge.weight * 1.0
    when 'related_to'
      edge.weight * 0.8
    when 'leads_to'
      edge.weight * 0.9
    when 'example_of'
      edge.weight * 0.6
    else
      edge.weight
    end
  end

  # Calculate edge color based on relationship type
  def calculate_edge_color(edge)
    case edge.relationship_type
    when 'prerequisite'
      '#ff6b6b'  # Red - important dependency
    when 'part_of'
      '#4ecdc4'  # Teal - hierarchical
    when 'related_to'
      '#95e1d3'  # Light teal - related
    when 'leads_to'
      '#f7dc6f'  # Yellow - progression
    when 'example_of'
      '#bb8fce'  # Purple - example
    else
      '#999999'  # Gray - default
    end
  end

  # Fetch edges for given nodes
  def fetch_edges_for_nodes(nodes)
    node_ids = nodes.pluck(:id)

    KnowledgeEdge.where(knowledge_node_id: node_ids)
                 .where(related_node_id: node_ids)
                 .where(active: true)
  end

  # Generate hierarchical layout (alternative to force-directed)
  def generate_hierarchical_layout(nodes)
    positions = {}
    levels = nodes.group_by(&:level)

    # Define Y positions for each level
    level_y = {
      'subject' => 100,
      'chapter' => 50,
      'concept' => 0,
      'detail' => -50
    }

    levels.each do |level, level_nodes|
      y_pos = level_y[level] || 0
      angle_step = (2 * Math::PI) / level_nodes.count

      level_nodes.each_with_index do |node, index|
        angle = angle_step * index
        radius = 50 + (level_nodes.count * 2)

        positions[node.id] = {
          x: (Math.cos(angle) * radius).round(2),
          y: y_pos,
          z: (Math.sin(angle) * radius).round(2)
        }
      end
    end

    positions
  end
end
