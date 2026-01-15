require 'rails_helper'

RSpec.describe KnowledgeNode, type: :model do
  let(:study_material) { create(:study_material) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:level) }
    it { is_expected.to validate_inclusion_of(:level).in_array(%w(subject chapter concept detail)) }
    it { is_expected.to validate_numericality_of(:difficulty).is_greater_than_or_equal_to(1).is_less_than_or_equal_to(5) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:study_material) }
    it { is_expected.to have_many(:outgoing_edges) }
    it { is_expected.to have_many(:incoming_edges) }
    it { is_expected.to have_many(:user_masteries) }
  end

  describe 'scopes' do
    let!(:subject_node) { create(:knowledge_node, study_material: study_material, level: 'subject') }
    let!(:chapter_node) { create(:knowledge_node, study_material: study_material, level: 'chapter') }

    it 'filters by level' do
      expect(KnowledgeNode.by_level('subject')).to include(subject_node)
      expect(KnowledgeNode.by_level('chapter')).not_to include(subject_node)
    end

    it 'filters active nodes' do
      subject_node.update(active: false)
      expect(KnowledgeNode.active).not_to include(subject_node)
      expect(KnowledgeNode.active).to include(chapter_node)
    end
  end

  describe '#add_prerequisite' do
    let(:concept1) { create(:knowledge_node, study_material: study_material) }
    let(:concept2) { create(:knowledge_node, study_material: study_material) }

    it 'creates prerequisite relationship' do
      concept1.add_prerequisite(concept2)

      edge = concept1.outgoing_edges.find_by(related_node_id: concept2.id)
      expect(edge).to be_present
      expect(edge.relationship_type).to eq('prerequisite')
      expect(edge.weight).to eq(0.8)
    end
  end

  describe '#prerequisites' do
    let(:concept1) { create(:knowledge_node, study_material: study_material) }
    let(:concept2) { create(:knowledge_node, study_material: study_material) }

    it 'returns direct prerequisites' do
      concept1.add_prerequisite(concept2)
      expect(concept1.prerequisites).to include(concept2)
    end
  end

  describe '#all_prerequisites' do
    let(:concept1) { create(:knowledge_node, study_material: study_material) }
    let(:concept2) { create(:knowledge_node, study_material: study_material) }
    let(:concept3) { create(:knowledge_node, study_material: study_material) }

    it 'returns all prerequisites recursively' do
      concept1.add_prerequisite(concept2)
      concept2.add_prerequisite(concept3)

      all_prereqs = concept1.all_prerequisites
      expect(all_prereqs).to include(concept2, concept3)
    end
  end

  describe '#calculate_color' do
    let(:user) { create(:user) }
    let(:node) { create(:knowledge_node, study_material: study_material) }

    context 'when user has no mastery record' do
      it 'returns gray' do
        expect(node.calculate_color(user)).to eq('gray')
      end
    end

    context 'when mastery level is high' do
      it 'returns green' do
        create(:user_mastery, user: user, knowledge_node: node, mastery_level: 0.9)
        expect(node.calculate_color(user)).to eq('green')
      end
    end

    context 'when mastery level is low' do
      it 'returns red' do
        create(:user_mastery, user: user, knowledge_node: node, mastery_level: 0.2)
        expect(node.calculate_color(user)).to eq('red')
      end
    end

    context 'when mastery level is medium' do
      it 'returns yellow' do
        create(:user_mastery, user: user, knowledge_node: node, mastery_level: 0.6)
        expect(node.calculate_color(user)).to eq('yellow')
      end
    end
  end

  describe '#to_graph_json' do
    let(:user) { create(:user) }
    let(:node) { create(:knowledge_node, study_material: study_material) }

    it 'returns node as JSON' do
      json = node.to_graph_json(user)

      expect(json[:id]).to eq(node.id)
      expect(json[:name]).to eq(node.name)
      expect(json[:level]).to eq(node.level)
      expect(json[:color]).to be_present
    end
  end

  describe '#to_detailed_json' do
    let(:user) { create(:user) }
    let(:node) { create(:knowledge_node, study_material: study_material) }
    let(:prerequisite) { create(:knowledge_node, study_material: study_material) }

    before do
      node.add_prerequisite(prerequisite)
      create(:user_mastery, user: user, knowledge_node: node, mastery_level: 0.7)
    end

    it 'returns detailed node information' do
      json = node.to_detailed_json(user)

      expect(json[:id]).to eq(node.id)
      expect(json[:prerequisites]).to include(prerequisite.name)
      expect(json[:mastery_details]).to be_present
      expect(json[:mastery_details][:status]).to eq('learning')
    end
  end
end
