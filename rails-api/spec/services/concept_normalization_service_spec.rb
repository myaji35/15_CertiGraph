require 'rails_helper'

RSpec.describe ConceptNormalizationService, type: :service do
  let(:study_material) { create(:study_material) }
  let(:service) { described_class.new(study_material) }

  describe '#normalize_concept' do
    let(:concept) { create(:knowledge_node, study_material: study_material, name: '  REST API  ') }

    it 'normalizes concept name' do
      service.normalize_concept(concept)
      expect(concept.reload.normalized_name).to eq('rest api')
    end

    it 'returns true on success' do
      expect(service.normalize_concept(concept)).to be true
    end
  end

  describe '#detect_and_merge_duplicates' do
    let!(:primary) { create(:knowledge_node, study_material: study_material, name: 'REST API', normalized_name: 'rest api', is_primary: true) }
    let!(:duplicate) { create(:knowledge_node, study_material: study_material, name: 'Rest API', normalized_name: 'rest api', is_primary: false) }

    it 'merges duplicate concepts' do
      expect {
        service.detect_and_merge_duplicates
      }.to change { KnowledgeNode.where(active: true).count }.by(-1)
    end

    it 'keeps primary concept active' do
      service.detect_and_merge_duplicates
      expect(primary.reload.active).to be true
      expect(duplicate.reload.active).to be false
    end
  end

  describe '#merge_concepts' do
    let(:primary) { create(:knowledge_node, study_material: study_material, frequency: 5) }
    let(:duplicate) { create(:knowledge_node, study_material: study_material, frequency: 3) }
    let!(:qc) { create(:question_concept, knowledge_node: duplicate) }

    it 'moves question_concepts to primary' do
      expect {
        service.send(:merge_concepts, primary, duplicate)
      }.to change { primary.question_concepts.count }.by(1)
    end

    it 'combines frequency' do
      service.send(:merge_concepts, primary, duplicate)
      expect(primary.reload.frequency).to eq(8)
    end

    it 'deactivates duplicate' do
      service.send(:merge_concepts, primary, duplicate)
      expect(duplicate.reload.active).to be false
    end
  end

  describe '#standardize_concept_names' do
    let!(:concept) { create(:knowledge_node, study_material: study_material, name: '  API  Gateway  ') }

    it 'standardizes concept names' do
      count = service.standardize_concept_names
      expect(concept.reload.name).to eq('API Gateway')
    end
  end
end
