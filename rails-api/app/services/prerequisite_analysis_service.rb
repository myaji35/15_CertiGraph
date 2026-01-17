require 'httparty'

class PrerequisiteAnalysisService
  include HTTParty
  base_uri 'https://api.openai.com'

  def initialize(study_material)
    @study_material = study_material
    @api_key = ENV['OPENAI_API_KEY']
  end

  # Analyze all concepts and build prerequisite relationships
  def analyze_all_prerequisites
    nodes = @study_material.knowledge_nodes.active.by_level('concept')

    results = {
      total_nodes: nodes.count,
      analyzed: 0,
      relationships_created: 0,
      errors: []
    }

    nodes.each do |node|
      begin
        prerequisites = analyze_node_prerequisites(node)
        create_prerequisite_relationships(node, prerequisites)
        results[:analyzed] += 1
        results[:relationships_created] += prerequisites.size
      rescue => e
        results[:errors] << { node_id: node.id, error: e.message }
      end
    end

    results
  end

  # Analyze prerequisites for a single node
  def analyze_node_prerequisites(node)
    # Get related nodes from the same study material
    candidate_nodes = @study_material.knowledge_nodes
      .active
      .where.not(id: node.id)
      .where(level: ['concept', 'chapter'])

    return [] if candidate_nodes.empty?

    # Use GPT to analyze prerequisites
    prompt = build_prerequisite_prompt(node, candidate_nodes)
    response = call_openai_api(prompt)

    parse_prerequisite_response(response, candidate_nodes)
  end

  # Calculate prerequisite strength (mandatory, recommended, optional)
  def calculate_strength(weight)
    case weight
    when 0.8..1.0
      'mandatory'
    when 0.5..0.8
      'recommended'
    when 0.0..0.5
      'optional'
    else
      'optional'
    end
  end

  # Calculate dependency depth for a node
  def calculate_depth(node, visited = Set.new)
    return 0 if visited.include?(node.id)
    visited.add(node.id)

    prerequisites = node.prerequisites
    return 0 if prerequisites.empty?

    max_depth = prerequisites.map { |prereq| calculate_depth(prereq, visited.dup) }.max || 0
    max_depth + 1
  end

  # Detect circular dependencies
  def detect_circular_dependencies
    nodes = @study_material.knowledge_nodes.active
    circular_deps = []

    nodes.each do |node|
      path = []
      if has_circular_dependency?(node, path)
        circular_deps << path
      end
    end

    circular_deps.uniq
  end

  # Auto-generate prerequisites based on question relationships
  def generate_from_questions
    results = { created: 0, errors: [] }

    @study_material.questions.each do |question|
      begin
        # Extract concepts from question
        concepts = extract_concepts_from_question(question)

        # Analyze concept relationships
        if concepts.size >= 2
          create_concept_relationships(concepts, question)
          results[:created] += 1
        end
      rescue => e
        results[:errors] << { question_id: question.id, error: e.message }
      end
    end

    results
  end

  # Batch analysis for multiple nodes
  def batch_analyze(node_ids)
    nodes = KnowledgeNode.where(id: node_ids)
    results = []

    nodes.each do |node|
      prerequisites = analyze_node_prerequisites(node)
      results << {
        node_id: node.id,
        node_name: node.name,
        prerequisites: prerequisites
      }
    end

    results
  end

  # Generate prerequisite graph data
  def generate_graph_data
    nodes = @study_material.knowledge_nodes.active
    edges = KnowledgeEdge.where(knowledge_node: nodes, relationship_type: 'prerequisite')

    {
      nodes: nodes.map do |node|
        {
          id: node.id,
          name: node.name,
          level: node.level,
          difficulty: node.difficulty,
          importance: node.importance,
          depth: calculate_depth(node),
          prerequisite_count: node.prerequisites.count,
          dependent_count: node.dependents.count
        }
      end,
      edges: edges.map do |edge|
        {
          id: edge.id,
          from: edge.knowledge_node_id,
          to: edge.related_node_id,
          strength: edge.strength || calculate_strength(edge.weight),
          weight: edge.weight,
          depth: edge.depth || 1,
          confidence: edge.confidence_score || 0.0,
          reasoning: edge.llm_reasoning
        }
      end,
      statistics: {
        total_nodes: nodes.count,
        total_edges: edges.count,
        avg_prerequisites: edges.count.to_f / nodes.count,
        max_depth: nodes.map { |n| calculate_depth(n) }.max || 0
      }
    }
  end

  private

  def build_prerequisite_prompt(node, candidates)
    candidate_list = candidates.map { |c| "- #{c.name}: #{c.description}" }.join("\n")

    <<~PROMPT
      You are an educational ontology expert. Analyze the following concept and identify its prerequisites.

      Target Concept: #{node.name}
      Description: #{node.description}
      Level: #{node.level}
      Difficulty: #{node.difficulty}

      Candidate Prerequisites:
      #{candidate_list}

      Instructions:
      1. Identify which candidates are prerequisites for understanding the target concept
      2. Classify each prerequisite as:
         - mandatory (weight 0.8-1.0): Must be understood before target concept
         - recommended (weight 0.5-0.8): Helpful but not strictly required
         - optional (weight 0.0-0.5): Related but not necessary
      3. Explain your reasoning for each prerequisite

      Return a JSON array of prerequisites:
      [
        {
          "name": "concept name",
          "weight": 0.9,
          "strength": "mandatory",
          "reasoning": "explanation why this is a prerequisite"
        }
      ]

      Return only valid JSON, no additional text.
    PROMPT
  end

  def call_openai_api(prompt)
    return mock_response if Rails.env.test?

    response = self.class.post(
      '/v1/chat/completions',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'application/json'
      },
      body: {
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: 'You are an expert in educational prerequisite analysis.' },
          { role: 'user', content: prompt }
        ],
        temperature: 0.3,
        response_format: { type: 'json_object' }
      }.to_json
    )

    if response.success?
      JSON.parse(response.parsed_response['choices'][0]['message']['content'])
    else
      raise "OpenAI API error: #{response.code} - #{response.message}"
    end
  end

  def parse_prerequisite_response(response, candidates)
    prerequisites = []

    # Handle different response formats
    data = response.is_a?(String) ? JSON.parse(response) : response
    prereq_array = data['prerequisites'] || data['results'] || []

    prereq_array.each do |prereq_data|
      candidate = candidates.find { |c| c.name == prereq_data['name'] }
      next unless candidate

      prerequisites << {
        node: candidate,
        weight: prereq_data['weight'] || 0.5,
        strength: prereq_data['strength'] || 'optional',
        reasoning: prereq_data['reasoning'] || '',
        confidence: prereq_data['confidence'] || 0.7
      }
    end

    prerequisites
  end

  def create_prerequisite_relationships(node, prerequisites)
    prerequisites.each do |prereq|
      edge = node.outgoing_edges.find_or_initialize_by(
        related_node_id: prereq[:node].id,
        relationship_type: 'prerequisite'
      )

      edge.weight = prereq[:weight]
      edge.strength = prereq[:strength]
      edge.reasoning = prereq[:reasoning]
      edge.confidence_score = prereq[:confidence]
      edge.depth = calculate_depth(prereq[:node]) + 1
      edge.auto_generated = true
      edge.llm_reasoning = prereq[:reasoning]
      edge.save!
    end
  end

  def has_circular_dependency?(node, path, visited = Set.new)
    return false if visited.include?(node.id)

    if path.include?(node.id)
      path << node.id
      return true
    end

    visited.add(node.id)
    path << node.id

    node.prerequisites.each do |prereq|
      if has_circular_dependency?(prereq, path.dup, visited.dup)
        return true
      end
    end

    false
  end

  def extract_concepts_from_question(question)
    # Use simple keyword matching or LLM extraction
    # For now, return empty array - can be enhanced
    []
  end

  def create_concept_relationships(concepts, question)
    # Create relationships between concepts mentioned in the same question
    # This is a simplified version - can be enhanced with LLM analysis
  end

  def mock_response
    {
      'prerequisites' => [
        {
          'name' => 'Basic Concept',
          'weight' => 0.8,
          'strength' => 'mandatory',
          'reasoning' => 'This is a fundamental prerequisite',
          'confidence' => 0.85
        }
      ]
    }
  end
end
