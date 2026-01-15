require 'rails_helper'

RSpec.describe ErrorAnalysisService, type: :service do
  let(:user) { create(:user) }
  let(:study_set) { create(:study_set, user: user) }
  let(:study_material) { create(:study_material, study_set: study_set) }
  let(:question) { create(:question, study_material: study_material, answer: '②') }
  let(:analysis_result) { create(:analysis_result, user: user, question: question, study_set: study_set) }
  let(:service) { ErrorAnalysisService.new }

  before do
    create_user_history(user, study_material)
  end

  describe '#analyze_error_in_depth' do
    it '상세 오답 분석을 반환한다' do
      result = service.analyze_error_in_depth(user, question, '①', analysis_result)

      expect(result).to have_key(:error_classification)
      expect(result).to have_key(:conceptual_gaps)
      expect(result).to have_key(:error_patterns)
      expect(result).to have_key(:similar_mistakes)
      expect(result).to have_key(:knowledge_connections)
    end

    context 'error_classification' do
      it '오답 유형을 분류한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        classification = result[:error_classification]
        expect(['careless', 'concept_gap', 'mixed']).to include(classification[:type])
      end

      it '심각도를 평가한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        severity = result[:error_classification][:severity]
        expect(['low', 'medium', 'high']).to include(severity)
      end
    end

    context 'conceptual_gaps' do
      it '개념 격차를 식별한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        gaps = result[:conceptual_gaps]
        expect(gaps).to be_an(Array)
      end

      it '격차 수준을 계산한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        gaps = result[:conceptual_gaps]
        gaps.each do |gap|
          expect(gap[:gap_level]).to be_between(0, 1)
        end
      end

      it '중요한 격차를 표시한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        gaps = result[:conceptual_gaps]
        gaps.each do |gap|
          expect(gap).to have_key(:is_critical)
        end
      end
    end

    context 'error_patterns' do
      it '오답 패턴을 감지한다' do
        # 여러 오답을 생성
        create_list(:wrong_answer, 5, user: user, question: question, selected_answer: '①')

        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        patterns = result[:error_patterns]
        expect(patterns).to have_key(:frequently_selected_wrong_options)
        expect(patterns).to have_key(:temporal_patterns)
      end

      it '선택지 편향을 분석한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        patterns = result[:error_patterns]
        expect(patterns[:frequently_selected_wrong_options]).to be_an(Array)
      end
    end

    context 'similar_mistakes' do
      it '유사한 과거 오답을 찾는다' do
        # 같은 주제의 다른 오답 생성
        other_question = create(:question, study_material: study_material, topic: question.topic)
        create(:wrong_answer, user: user, question: other_question, selected_answer: '①')

        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        similar = result[:similar_mistakes]
        expect(similar).to be_an(Array)
      end

      it '유사 오답의 상세 정보를 포함한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        similar = result[:similar_mistakes]
        similar.each do |mistake|
          expect(mistake).to have_key(:question_id)
          expect(mistake).to have_key(:user_selected)
          expect(mistake).to have_key(:correct_answer)
          expect(mistake).to have_key(:attempt_count)
        end
      end
    end
  end

  describe '#generate_learning_path' do
    it '학습 경로를 생성한다' do
      result = service.generate_learning_path(user, analysis_result, study_set)

      expect(result).to have_key(:weak_concepts)
      expect(result).to have_key(:learning_path)
      expect(result).to have_key(:practice_questions)
      expect(result).to have_key(:estimated_hours)
    end

    context 'learning_path' do
      it '단계별 학습 계획을 포함한다' do
        result = service.generate_learning_path(user, analysis_result, study_set)

        path = result[:learning_path]
        expect(path).to be_an(Array)

        path.each do |step|
          expect(step).to have_key(:step)
          expect(step).to have_key(:concept)
          expect(step).to have_key(:action)
          expect(step).to have_key(:estimated_minutes)
        end
      end

      it '선행 개념을 지정한다' do
        result = service.generate_learning_path(user, analysis_result, study_set)

        path = result[:learning_path]
        path.each do |step|
          expect(step).to have_key(:prerequisites_before_this)
        end
      end
    end

    context 'practice_questions' do
      it '연습 문제를 추천한다' do
        result = service.generate_learning_path(user, analysis_result, study_set)

        questions = result[:practice_questions]
        expect(questions).to be_a(Hash)
      end
    end

    context 'time_estimation' do
      it '학습 시간을 추정한다' do
        result = service.generate_learning_path(user, analysis_result, study_set)

        hours = result[:estimated_hours]
        expect(hours).to be > 0
      end
    end
  end

  describe 'Error Classification Accuracy' do
    context '부주의 오답 감지' do
      it '반대 지시문을 감지한다' do
        opposite_question = create(
          :question,
          study_material: study_material,
          content: '다음 중 틀린 것은?',
          answer: '②'
        )

        result = service.analyze_error_in_depth(user, opposite_question, '②', analysis_result)

        classification = result[:error_classification]
        expect(classification[:careless_indicators]).to include('반대 지시문 오독')
      end
    end

    context '개념 격차 감지' do
      it '선행 개념 미숙달을 감지한다' do
        result = service.analyze_error_in_depth(user, question, '①', analysis_result)

        classification = result[:error_classification]
        expect(classification[:concept_gap_indicators]).to be_an(Array)
      end
    end
  end

  describe 'Concept Connection Analysis' do
    it '개념 계층 구조를 분석한다' do
      result = service.analyze_error_in_depth(user, question, '①', analysis_result)

      connections = result[:knowledge_connections]
      expect(connections).to have_key(:concept_hierarchy)
    end

    it '선행 개념 체인의 격차를 식별한다' do
      result = service.analyze_error_in_depth(user, question, '①', analysis_result)

      connections = result[:knowledge_connections]
      expect(connections).to have_key(:knowledge_gaps_in_chain)
    end

    it '중요한 개념 교점을 찾는다' do
      result = service.analyze_error_in_depth(user, question, '①', analysis_result)

      connections = result[:knowledge_connections]
      expect(connections).to have_key(:critical_junctions)
    end
  end

  describe 'Integration with GraphRAG Results' do
    it 'GraphRAG 분석 결과를 활용한다' do
      # 사전에 GraphRAG 분석 결과 설정
      analysis_result.update!(
        related_concepts: [
          { concept_id: 1, name: '개념1', relationship_type: 'prerequisite' }
        ]
      )

      result = service.generate_learning_path(user, analysis_result, study_set)

      expect(result).to be_present
    end
  end

  private

  def create_user_history(user, study_material)
    questions = create_list(:question, 5, study_material: study_material)

    # 일부 정답, 일부 오답 생성
    questions[0..1].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: true)
    end

    questions[2..4].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: false)
      create(:wrong_answer, user: user, question: q, selected_answer: '①')
    end
  end
end
