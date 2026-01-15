require 'rails_helper'

RSpec.describe ThreeDGraphService, type: :service do
  let(:user) { create(:user) }
  let(:study_material) { create(:study_material, user: user) }
  let(:service) { described_class.new(study_material, user) }

  describe '#initialize' do
    it 'sets study_material and user' do
      expect(service.study_material).to eq(study_material)
      expect(service.user).to eq(user)
    end
  end

  describe '#generate_3d_graph' do
    let!(:node1) { create(:knowledge_node, study_material: study_material, name: 'Concept A', level: 'concept') }
    let!(:node2) { create(:knowledge_node, study_material: study_material, name: 'Concept B', level: 'concept') }
    let!(:edge) { create(:knowledge_edge, knowledge_node: node1, related_node: node2, weight: 0.8) }

    it 'generates graph data with nodes and edges' do
      result = service.generate_3d_graph

      expect(result).to have_key(:nodes)
      expect(result).to have_key(:edges)
      expect(result).to have_key(:statistics)

      expect(result[:nodes].count).to eq(2)
      expect(result[:edges].count).to eq(1)
    end

    it 'includes 3D positions for all nodes' do
      result = service.generate_3d_graph

      result[:nodes].each do |node|
        expect(node[:position]).to have_key(:x)
        expect(node[:position]).to have_key(:y)
        expect(node[:position]).to have_key(:z)
      end
    end

    it 'includes node metadata' do
      result = service.generate_3d_graph
      node_data = result[:nodes].first

      expect(node_data).to include(
        :id,
        :name,
        :level,
        :difficulty,
        :importance,
        :color,
        :mastery_level,
        :size
      )
    end

    it 'includes edge metadata' do
      result = service.generate_3d_graph
      edge_data = result[:edges].first

      expect(edge_data).to include(
        :id,
        :source,
        :target,
        :relationship_type,
        :weight,
        :strength,
        :color
      )
    end
  end

  describe '#initialize_positions' do
    let!(:nodes) { create_list(:knowledge_node, 10, study_material: study_material) }

    it 'creates positions for all nodes' do
      positions = service.initialize_positions(KnowledgeNode.where(id: nodes.map(&:id)))

      expect(positions.keys.count).to eq(10)
    end

    it 'distributes nodes evenly on a sphere' do
      positions = service.initialize_positions(KnowledgeNode.where(id: nodes.map(&:id)))

      positions.values.each do |pos|
        # Check that positions are within sphere radius
        distance = Math.sqrt(pos[:x]**2 + pos[:y]**2 + pos[:z]**2)
        expect(distance).to be <= described_class::SPHERE_RADIUS * 1.1  # Allow 10% margin
      end
    end
  end

  describe '#fibonacci_sphere_point' do
    it 'generates a point on a sphere' do
      point = service.fibonacci_sphere_point(0, 10)

      expect(point).to have_key(:x)
      expect(point).to have_key(:y)
      expect(point).to have_key(:z)
    end

    it 'keeps points within sphere radius' do
      (0...10).each do |i|
        point = service.fibonacci_sphere_point(i, 10)
        distance = Math.sqrt(point[:x]**2 + point[:y]**2 + point[:z]**2)

        expect(distance).to be <= described_class::SPHERE_RADIUS * 1.1
      end
    end
  end

  describe '#calculate_node_color' do
    let(:node) { create(:knowledge_node, study_material: study_material) }

    context 'when user has no mastery' do
      it 'returns gray color' do
        color = service.send(:calculate_node_color, node)
        expect(color).to eq('#808080')
      end
    end

    context 'when user has mastered the concept' do
      before do
        create(:user_mastery, user: user, knowledge_node: node, color: 'green', mastery_level: 0.9)
      end

      it 'returns green color' do
        color = service.send(:calculate_node_color, node)
        expect(color).to eq('#00ff00')
      end
    end

    context 'when user is learning the concept' do
      before do
        create(:user_mastery, user: user, knowledge_node: node, color: 'yellow', mastery_level: 0.6)
      end

      it 'returns yellow color' do
        color = service.send(:calculate_node_color, node)
        expect(color).to eq('#ffff00')
      end
    end

    context 'when concept is weak' do
      before do
        create(:user_mastery, user: user, knowledge_node: node, color: 'red', mastery_level: 0.3)
      end

      it 'returns red color' do
        color = service.send(:calculate_node_color, node)
        expect(color).to eq('#ff0000')
      end
    end
  end

  describe '#calculate_node_size' do
    let(:node) do
      create(:knowledge_node,
             study_material: study_material,
             importance: 5)
    end

    it 'calculates size based on importance' do
      size = service.send(:calculate_node_size, node)
      expect(size).to be > 5.0  # base_size + importance_factor
    end

    it 'increases size with more connections' do
      other_nodes = create_list(:knowledge_node, 5, study_material: study_material)
      other_nodes.each do |other_node|
        create(:knowledge_edge, knowledge_node: node, related_node: other_node)
      end

      size = service.send(:calculate_node_size, node)
      expect(size).to be > 7.0  # Includes connection factor
    end
  end

  describe '#calculate_edge_strength' do
    let(:node1) { create(:knowledge_node, study_material: study_material) }
    let(:node2) { create(:knowledge_node, study_material: study_material) }

    it 'increases strength for prerequisite relationships' do
      edge = create(:knowledge_edge,
                    knowledge_node: node1,
                    related_node: node2,
                    relationship_type: 'prerequisite',
                    weight: 0.8)

      strength = service.send(:calculate_edge_strength, edge)
      expect(strength).to eq(0.8 * 1.2)
    end

    it 'applies different strengths for different relationship types' do
      edge_prerequisite = create(:knowledge_edge,
                                 knowledge_node: node1,
                                 related_node: node2,
                                 relationship_type: 'prerequisite',
                                 weight: 0.8)

      edge_related = create(:knowledge_edge,
                            knowledge_node: node1,
                            related_node: create(:knowledge_node, study_material: study_material),
                            relationship_type: 'related_to',
                            weight: 0.8)

      strength_prerequisite = service.send(:calculate_edge_strength, edge_prerequisite)
      strength_related = service.send(:calculate_edge_strength, edge_related)

      expect(strength_prerequisite).to be > strength_related
    end
  end

  describe '#calculate_edge_color' do
    let(:node1) { create(:knowledge_node, study_material: study_material) }
    let(:node2) { create(:knowledge_node, study_material: study_material) }

    it 'returns different colors for different relationship types' do
      edge_prerequisite = create(:knowledge_edge,
                                 knowledge_node: node1,
                                 related_node: node2,
                                 relationship_type: 'prerequisite')

      edge_part_of = create(:knowledge_edge,
                            knowledge_node: node1,
                            related_node: create(:knowledge_node, study_material: study_material),
                            relationship_type: 'part_of')

      color_prerequisite = service.send(:calculate_edge_color, edge_prerequisite)
      color_part_of = service.send(:calculate_edge_color, edge_part_of)

      expect(color_prerequisite).not_to eq(color_part_of)
      expect(color_prerequisite).to eq('#ff6b6b')
      expect(color_part_of).to eq('#4ecdc4')
    end
  end

  describe '#generate_hierarchical_layout' do
    let!(:subject_node) { create(:knowledge_node, study_material: study_material, level: 'subject') }
    let!(:chapter_node) { create(:knowledge_node, study_material: study_material, level: 'chapter') }
    let!(:concept_node) { create(:knowledge_node, study_material: study_material, level: 'concept') }

    it 'positions nodes at different Y levels based on hierarchy' do
      nodes = KnowledgeNode.where(id: [subject_node.id, chapter_node.id, concept_node.id])
      positions = service.send(:generate_hierarchical_layout, nodes)

      expect(positions[subject_node.id][:y]).to be > positions[chapter_node.id][:y]
      expect(positions[chapter_node.id][:y]).to be > positions[concept_node.id][:y]
    end
  end
end
