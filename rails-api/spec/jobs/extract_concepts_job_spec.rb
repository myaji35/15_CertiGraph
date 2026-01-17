require 'rails_helper'

RSpec.describe ExtractConceptsJob, type: :job do
  let(:study_material) { create(:study_material) }

  describe '#perform' do
    let(:extraction_result) do
      {
        total_questions: 10,
        processed_questions: 10,
        unique_concepts: 15
      }
    end

    before do
      allow_any_instance_of(ConceptExtractionService).to receive(:extract_from_all_questions).and_return(extraction_result)
      allow_any_instance_of(ConceptNormalizationService).to receive(:normalize_all_concepts).and_return({})
    end

    it 'calls ConceptExtractionService' do
      expect_any_instance_of(ConceptExtractionService).to receive(:extract_from_all_questions)
      described_class.perform_now(study_material.id)
    end

    it 'calls ConceptNormalizationService' do
      expect_any_instance_of(ConceptNormalizationService).to receive(:normalize_all_concepts)
      described_class.perform_now(study_material.id)
    end

    it 'updates study_material metadata' do
      described_class.perform_now(study_material.id)
      expect(study_material.reload.graph_metadata['concepts_extracted']).to be true
      expect(study_material.graph_metadata['concepts_normalized']).to be true
    end

    context 'when extraction fails' do
      before do
        allow_any_instance_of(ConceptExtractionService).to receive(:extract_from_all_questions).and_raise(StandardError, 'Test error')
      end

      it 'updates study_material with error' do
        expect {
          described_class.perform_now(study_material.id)
        }.to raise_error(StandardError)

        expect(study_material.reload.graph_error).to include('Concept extraction failed')
      end
    end
  end
end
