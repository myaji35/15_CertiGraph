require 'rails_helper'

RSpec.describe QuestionConcept, type: :model do
  let(:study_material) { create(:study_material) }
  let(:question) { create(:question, study_material: study_material) }
  let(:knowledge_node) { create(:knowledge_node, study_material: study_material) }

  describe 'associations' do
    it { should belong_to(:question) }
    it { should belong_to(:knowledge_node) }
  end

  describe 'validations' do
    subject { build(:question_concept, question: question, knowledge_node: knowledge_node) }

    it { should validate_uniqueness_of(:question_id).scoped_to(:knowledge_node_id) }
    it { should validate_inclusion_of(:extraction_method).in_array(%w[ai manual rule_based]) }

    it 'validates importance_level range' do
      qc = build(:question_concept, importance_level: 11)
      expect(qc).not_to be_valid
    end

    it 'validates relevance_score range' do
      qc = build(:question_concept, relevance_score: 1.5)
      expect(qc).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:primary) { create(:question_concept, question: question, knowledge_node: knowledge_node, is_primary_concept: true) }
    let!(:secondary) { create(:question_concept, is_primary_concept: false) }

    it 'returns primary concepts' do
      expect(QuestionConcept.primary_concepts).to include(primary)
      expect(QuestionConcept.primary_concepts).not_to include(secondary)
    end
  end

  describe '.for_question' do
    let(:question2) { create(:question, study_material: study_material) }
    let!(:qc1) { create(:question_concept, question: question, knowledge_node: knowledge_node, importance_level: 8) }
    let!(:qc2) { create(:question_concept, question: question, importance_level: 5) }
    let!(:qc3) { create(:question_concept, question: question2) }

    it 'returns concepts for specific question ordered by importance' do
      concepts = QuestionConcept.for_question(question.id)
      expect(concepts).to eq([qc1, qc2])
    end
  end

  describe '.concept_frequency' do
    let(:node2) { create(:knowledge_node, study_material: study_material) }
    let!(:qc1) { create(:question_concept, knowledge_node: knowledge_node) }
    let!(:qc2) { create(:question_concept, knowledge_node: knowledge_node) }
    let!(:qc3) { create(:question_concept, knowledge_node: node2) }

    it 'returns concept frequency sorted by count' do
      frequencies = QuestionConcept.concept_frequency
      expect(frequencies[knowledge_node.id]).to eq(2)
      expect(frequencies[node2.id]).to eq(1)
    end
  end

  describe '#to_json_api' do
    let(:qc) { create(:question_concept, question: question, knowledge_node: knowledge_node) }

    it 'returns correct JSON structure' do
      json = qc.to_json_api
      expect(json).to include(:id, :question_id, :concept, :importance_level, :relevance_score)
      expect(json[:concept]).to include(:id, :name, :level, :difficulty)
    end
  end
end
