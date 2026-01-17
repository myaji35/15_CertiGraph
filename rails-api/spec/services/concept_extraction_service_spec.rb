require 'rails_helper'

RSpec.describe ConceptExtractionService, type: :service do
  let(:study_material) { create(:study_material) }
  let(:service) { described_class.new(study_material) }
  let(:question) { create(:question, study_material: study_material, content: 'What is REST API?') }

  describe '#initialize' do
    it 'sets study_material and openai_client' do
      expect(service.study_material).to eq(study_material)
      expect(service.openai_client).to be_a(OpenaiClient)
    end
  end

  describe '#extract_from_question' do
    let(:mock_response) do
      {
        'concepts' => [
          {
            'name' => 'REST API',
            'level' => 'concept',
            'description' => 'Representational State Transfer Application Programming Interface',
            'difficulty' => 3,
            'importance' => 8,
            'is_primary' => true
          }
        ]
      }
    end

    before do
      allow_any_instance_of(OpenaiClient).to receive(:reason_with_gpt4o).and_return(mock_response.to_json)
    end

    it 'extracts concepts from question content' do
      expect {
        service.extract_from_question(question)
      }.to change { KnowledgeNode.count }.by(1)
    end

    it 'creates question_concept associations' do
      expect {
        service.extract_from_question(question)
      }.to change { QuestionConcept.count }.by(1)
    end

    it 'returns array of created concepts' do
      concepts = service.extract_from_question(question)
      expect(concepts).to be_an(Array)
      expect(concepts.first).to be_a(KnowledgeNode)
    end
  end

  describe '#extract_from_all_questions' do
    let!(:question1) { create(:question, study_material: study_material) }
    let!(:question2) { create(:question, study_material: study_material) }

    before do
      allow(service).to receive(:extract_from_question).and_return([])
    end

    it 'processes all questions' do
      expect(service).to receive(:extract_from_question).twice
      service.extract_from_all_questions
    end

    it 'returns statistics' do
      result = service.extract_from_all_questions
      expect(result).to include(:total_questions, :processed_questions, :unique_concepts)
    end
  end

  describe '#build_hierarchy' do
    let!(:subject_node) { create(:knowledge_node, study_material: study_material, name: 'Computer Science', level: 'subject') }
    let!(:chapter_node) { create(:knowledge_node, study_material: study_material, name: 'Networking', level: 'chapter', parent_name: 'Computer Science') }
    let!(:concept_node) { create(:knowledge_node, study_material: study_material, name: 'REST API', level: 'concept', parent_name: 'Networking') }

    it 'creates hierarchical relationships' do
      expect {
        service.build_hierarchy
      }.to change { KnowledgeEdge.count }
    end
  end
end
