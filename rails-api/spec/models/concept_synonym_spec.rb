require 'rails_helper'

RSpec.describe ConceptSynonym, type: :model do
  let(:study_material) { create(:study_material) }
  let(:knowledge_node) { create(:knowledge_node, study_material: study_material) }

  describe 'associations' do
    it { should belong_to(:knowledge_node) }
  end

  describe 'validations' do
    subject { build(:concept_synonym, knowledge_node: knowledge_node) }

    it { should validate_presence_of(:synonym_name) }
    it { should validate_uniqueness_of(:synonym_name).scoped_to(:knowledge_node_id) }
    it { should validate_inclusion_of(:synonym_type).in_array(%w[synonym abbreviation alias related_term]) }
    it { should validate_inclusion_of(:source).in_array(%w[manual ai_extracted user_defined]) }

    it 'validates similarity_score range' do
      synonym = build(:concept_synonym, similarity_score: 1.5)
      expect(synonym).not_to be_valid
      expect(synonym.errors[:similarity_score]).to include('must be greater than or equal to 0.0')
    end
  end

  describe 'scopes' do
    let!(:active_synonym) { create(:concept_synonym, knowledge_node: knowledge_node, active: true) }
    let!(:inactive_synonym) { create(:concept_synonym, knowledge_node: knowledge_node, active: false, synonym_name: 'inactive') }

    it 'returns active synonyms' do
      expect(ConceptSynonym.active).to include(active_synonym)
      expect(ConceptSynonym.active).not_to include(inactive_synonym)
    end
  end

  describe '.find_concept_by_synonym' do
    let!(:synonym) { create(:concept_synonym, synonym_name: 'API', knowledge_node: knowledge_node) }

    it 'finds concept by exact synonym match' do
      concept = ConceptSynonym.find_concept_by_synonym('API', study_material.id)
      expect(concept).to eq(knowledge_node)
    end

    it 'finds concept by case-insensitive match' do
      concept = ConceptSynonym.find_concept_by_synonym('api', study_material.id)
      expect(concept).to eq(knowledge_node)
    end

    it 'returns nil for non-existent synonym' do
      concept = ConceptSynonym.find_concept_by_synonym('NonExistent', study_material.id)
      expect(concept).to be_nil
    end
  end

  describe '#to_json_api' do
    let(:synonym) { create(:concept_synonym, knowledge_node: knowledge_node) }

    it 'returns correct JSON structure' do
      json = synonym.to_json_api
      expect(json).to include(:id, :synonym_name, :synonym_type, :similarity_score, :source, :active, :knowledge_node_name)
    end
  end
end
