require 'rails_helper'

RSpec.describe KnowledgeGraphService, type: :service do
  let(:study_material) { create(:study_material) }
  let(:service) { described_class.new(study_material) }
  let(:question) { create(:question, study_material: study_material) }

  describe '#extract_concepts' do
    it 'extracts concepts from question' do
      # Mock LLM response
      allow_any_instance_of(OpenAIClient).to receive(:chat).and_return(
        {
          'choices' => [
            {
              'message' => {
                'content' => '[{"name": "개념1", "level": "concept", "description": "설명1", "difficulty": 3, "importance": 4}]'
              }
            }
          ]
        }
      )

      concepts = service.extract_concepts(question)

      expect(concepts).to be_an(Array)
      expect(concepts.first[:name]).to eq('개념1')
    end
  end

  describe '#create_or_update_node' do
    let(:concept_data) do
      {
        name: 'Test Concept',
        level: 'concept',
        description: 'Test description',
        difficulty: 3,
        importance: 4
      }
    end

    it 'creates new node' do
      expect {
        service.create_or_update_node(concept_data)
      }.to change { KnowledgeNode.count }.by(1)
    end

    it 'updates existing node' do
      node = create(:knowledge_node, study_material: study_material, name: 'Test Concept')

      service.create_or_update_node(concept_data.merge(description: 'Updated description'))

      expect(node.reload.description).to eq('Updated description')
    end
  end

  describe '#graph_statistics' do
    before do
      create_list(:knowledge_node, 5, study_material: study_material)
      create_list(:knowledge_edge, 3, knowledge_node: KnowledgeNode.first)
    end

    it 'returns graph statistics' do
      stats = service.graph_statistics

      expect(stats).to include(
        :total_nodes,
        :total_edges,
        :nodes_by_level,
        :relationships_by_type,
        :avg_connections_per_node
      )
      expect(stats[:total_nodes]).to be > 0
    end
  end

  describe '#find_learning_path' do
    let(:node1) { create(:knowledge_node, study_material: study_material, name: 'Node1') }
    let(:node2) { create(:knowledge_node, study_material: study_material, name: 'Node2') }
    let(:node3) { create(:knowledge_node, study_material: study_material, name: 'Node3') }

    before do
      node1.add_related_concept(node2)
      node2.add_related_concept(node3)
    end

    it 'finds path between two nodes' do
      path = service.find_learning_path(node1, node3)

      expect(path).to be_present
      expect(path.first).to eq(node1)
      expect(path.last).to eq(node3)
    end
  end

  describe '#export_graph_as_json' do
    let(:user) { create(:user) }

    before do
      create_list(:knowledge_node, 3, study_material: study_material)
      create_list(:knowledge_edge, 2, knowledge_node: KnowledgeNode.first)
    end

    it 'exports graph data as JSON' do
      graph_data = service.export_graph_as_json(user)

      expect(graph_data).to include(:nodes, :edges, :stats)
      expect(graph_data[:nodes]).to be_an(Array)
      expect(graph_data[:edges]).to be_an(Array)
      expect(graph_data[:stats]).to be_a(Hash)
    end
  end
end
