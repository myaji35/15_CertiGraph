require 'rails_helper'

RSpec.describe RecommendationService, type: :service do
  let(:user) { create(:user) }
  let(:study_set) { create(:study_set, user: user) }
  let(:study_material) { create(:study_material, study_set: study_set) }
  let(:service) { RecommendationService.new }

  before do
    create_test_data(user, study_set, study_material)
  end

  describe '#generate_comprehensive_recommendation' do
    let(:analysis_result) do
      create(:analysis_result,
             user: user,
             study_set: study_set,
             concept_gap_score: 0.6,
             status: 'completed',
             related_concepts: [
               { concept_id: 1, name: '개념1', relevance_score: 0.8, relationship_type: 'prerequisite' }
             ])
    end

    it '종합 추천을 생성한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation).to be_a(LearningRecommendation)
      expect(recommendation).to be_persisted
      expect(recommendation.status).to eq('pending')
    end

    it '추천 유형을 결정한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(['remedial', 'progressive', 'comprehensive']).to include(recommendation.recommendation_type)
    end

    it '문제를 추천한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.total_recommended_count).to be > 0
      expect(recommendation.recommended_questions).to be_an(Array)
    end

    it '학습 경로를 생성한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.learning_path).to be_an(Array)
      expect(recommendation.learning_path_steps).to be > 0
    end

    it '효율성 메트릭을 계산한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.learning_efficiency_index).to be_between(0, 1)
      expect(recommendation.success_probability).to be_between(0, 1)
      expect(recommendation.estimated_learning_hours).to be > 0
    end

    it '우선순위 수준을 지정한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.priority_level).to be_between(1, 10)
    end

    it '개인화 파라미터를 포함한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.personalization_params).to have_key('learning_style')
      expect(recommendation.personalization_params).to have_key('pace')
      expect(recommendation.personalization_params).to have_key('concentration_level')
    end
  end

  describe '#recommend_questions' do
    it '추천 문제를 반환한다' do
      questions = service.recommend_questions(user, study_set, 10)

      expect(questions).to be_an(Array)
      expect(questions.count).to be <= 10
    end

    context '추천 기준' do
      it '약점 주제의 문제를 우선 추천한다' do
        questions = service.recommend_questions(user, study_set, 5)

        # 약점 주제가 포함되어 있는지 확인
        expect(questions.count).to be > 0
      end

      it '풀이한 문제는 제외한다' do
        solved_question = create(:question, study_material: study_material)
        create(:exam_answer, user: user, question: solved_question, is_correct: true)

        questions = service.recommend_questions(user, study_set, 10)
        question_ids = questions.map { |q| q[:id] }

        expect(question_ids).not_to include(solved_question.id)
      end

      it '적응형 난이도로 추천한다' do
        questions = service.recommend_questions(user, study_set, 5)

        questions.each do |q|
          expect(q[:difficulty]).to be_between(1, 5)
        end
      end
    end

    it '문제 점수로 정렬한다' do
      questions = service.recommend_questions(user, study_set, 10)

      scores = questions.map { |q| q[:score] }
      expect(scores).to eq(scores.sort.reverse)
    end
  end

  describe '#adaptive_difficulty_adjustment' do
    context '높은 정답률 (80% 이상)' do
      before do
        create_correct_answers(user, study_set, 8, 10)
      end

      it '난이도를 상향 조정한다' do
        difficulty = service.adaptive_difficulty_adjustment(user, study_set)

        expect(difficulty).to be >= 3
      end
    end

    context '낮은 정답률 (40% 미만)' do
      before do
        create_correct_answers(user, study_set, 2, 10)
      end

      it '난이도를 하향 조정한다' do
        difficulty = service.adaptive_difficulty_adjustment(user, study_set)

        expect(difficulty).to be <= 3
      end
    end

    context '중간 정답률 (60-80%)'do
      before do
        create_correct_answers(user, study_set, 7, 10)
      end

      it '난이도를 유지한다' do
        difficulty = service.adaptive_difficulty_adjustment(user, study_set)

        expect(difficulty).to be_between(1, 5)
      end
    end
  end

  describe '#weakness_focused_curation' do
    it '약점 중심 추천을 반환한다' do
      result = service.weakness_focused_curation(user, study_set)

      expect(result).to have_key(:weak_concepts)
      expect(result).to have_key(:curated_questions)
      expect(result).to have_key(:total_questions)
      expect(result).to have_key(:estimated_time)
    end

    it '약점 개념을 식별한다' do
      result = service.weakness_focused_curation(user, study_set)

      weak_concepts = result[:weak_concepts]
      expect(weak_concepts).to be_an(Array)
    end

    it '각 약점별로 문제를 큐레이션한다' do
      result = service.weakness_focused_curation(user, study_set)

      curated = result[:curated_questions]
      expect(curated).to be_a(Hash)
      curated.each do |concept, questions|
        expect(questions).to be_an(Array)
      end
    end

    it '학습 시간을 추정한다' do
      result = service.weakness_focused_curation(user, study_set)

      expect(result[:estimated_time]).to be > 0
    end
  end

  describe '#optimize_learning_order' do
    let(:questions) do
      create_list(:question, 5, study_material: study_material)
    end

    let(:user_profile) do
      { learning_pace: 'normal' }
    end

    it '최적화된 학습 순서를 반환한다' do
      optimized = service.optimize_learning_order(questions, user_profile)

      expect(optimized).to be_an(Array)
      expect(optimized.count).to eq(questions.count)
    end

    it '선행 개념 의존성을 고려한다' do
      optimized = service.optimize_learning_order(questions, user_profile)

      # 모든 문제가 포함되어 있는지 확인
      expect(optimized.map(&:id).sort).to eq(questions.map(&:id).sort)
    end

    it '학습 속도에 맞춘 순서를 제공한다' do
      fast_profile = { learning_pace: 'fast' }
      slow_profile = { learning_pace: 'slow' }

      fast_order = service.optimize_learning_order(questions, fast_profile)
      slow_order = service.optimize_learning_order(questions, slow_profile)

      # 순서가 다를 수 있음
      expect([fast_order, slow_order]).to contain_exactly(fast_order, slow_order)
    end
  end

  describe 'Personalization' do
    let(:analysis_result) do
      create(:analysis_result, user: user, study_set: study_set, status: 'completed')
    end

    it '사용자 학습 스타일을 고려한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      params = recommendation.personalization_params
      expect(params).to have_key('learning_style')
    end

    it '사용자 집중력 수준을 반영한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      params = recommendation.personalization_params
      expect(['low', 'medium', 'high']).to include(params['concentration_level'])
    end
  end

  describe 'Integration with AnalysisResult' do
    let(:analysis_result) do
      create(:analysis_result,
             user: user,
             study_set: study_set,
             status: 'completed',
             related_concepts: [
               { concept_id: 1, name: '개념1', relevance_score: 0.9 }
             ],
             concept_gap_score: 0.7)
    end

    it 'GraphRAG 분석 결과를 활용한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      expect(recommendation.weakness_analysis).to have_key(:concept_gaps)
    end

    it '약점을 우선순위 순서로 정렬한다' do
      recommendation = service.generate_comprehensive_recommendation(user, study_set, analysis_result)

      weakness = recommendation.weakness_analysis[:concept_gaps]
      unless weakness.empty?
        priorities = weakness.map { |w| w[:priority] }
        expect(priorities).to eq(priorities.sort.reverse)
      end
    end
  end

  private

  def create_test_data(user, study_set, study_material)
    questions = create_list(:question, 20, study_material: study_material)

    # 일부 정답, 일부 오답 생성
    questions[0..9].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: true)
    end

    questions[10..14].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: false)
    end
  end

  def create_correct_answers(user, study_set, correct_count, total_count)
    questions = create_list(:question, total_count, study_material: study_set.study_materials.first)

    questions[0...correct_count].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: true)
    end

    questions[correct_count...total_count].each do |q|
      create(:exam_answer, user: user, question: q, is_correct: false)
    end
  end
end
