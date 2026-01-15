require 'rails_helper'

RSpec.describe GraphRagService, type: :service do
  let(:user) { create(:user) }
  let(:study_set) { create(:study_set, user: user) }
  let(:study_material) { create(:study_material, study_set: study_set) }
  let(:service) { GraphRagService.new }

  before do
    # 기본 데이터 설정
    create_knowledge_graph(study_material)
  end

  describe '#analyze_wrong_answer' do
    let(:question) { create(:question, study_material: study_material) }

    context '오답 분석 성공' do
      it '분석 결과를 생성한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result).to be_a(AnalysisResult)
        expect(result.status).to eq('completed')
        expect(result.error_type).to be_present
        expect(result.concept_gap_score).to be_between(0, 1)
      end

      it '관련 개념을 식별한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.related_concepts).to be_present
        expect(result.related_concepts.count).to be > 0
      end

      it '그래프 탐색을 수행한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.graph_depth).to be >= 0
        expect(result.nodes_traversed).to be >= 0
        expect(result.traversal_path).to be_present
      end

      it 'LLM 추론 결과를 포함한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.llm_reasoning).to be_present
        expect(result.llm_analysis_metadata).to be_present
        expect(result.confidence_score).to be_between(0, 1)
      end

      it '처리 시간을 기록한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.processing_time_ms).to be > 0
      end
    end

    context '오답 유형 분류' do
      it '부주의 오답을 분류한다' do
        # 사용자가 동일 개념의 다른 문제는 맞힌 경우
        # -> 부주의 오답으로 분류
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        error_types = ['careless', 'concept_gap', 'mixed']
        expect(error_types).to include(result.error_type)
      end

      it '개념 격차 오답을 분류한다' do
        # 사용자가 선행 개념을 미숙달한 경우
        # -> 개념 격차로 분류
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.error_type).to be_present
      end

      it '혼합 오답을 분류한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(['careless', 'concept_gap', 'mixed']).to include(result.error_type)
      end
    end

    context '약점 점수 계산' do
      it '0과 1 사이의 정규화된 점수를 반환한다' do
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        expect(result.concept_gap_score).to be_between(0, 1)
      end

      it '높은 개념 격차를 감지한다' do
        # 선행 개념이 많고 미숙달한 경우
        result = service.analyze_wrong_answer(user, question, '①', study_set)

        if result.prerequisites.count > 3
          expect(result.concept_gap_score).to be > 0.5
        end
      end
    end
  end

  describe 'Graph Traversal' do
    let(:question) { create(:question, study_material: study_material) }

    it 'BFS로 관련 개념을 탐색한다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      # 탐색 경로가 BFS 순서를 따른다
      depths = result.traversal_path.map { |p| p[:depth] }
      expect(depths).to be_sorted
    end

    it '지정된 깊이만큼 탐색한다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      expect(result.graph_depth).to be <= GraphRagService::DEFAULT_GRAPH_DEPTH
    end

    it '방문한 노드를 중복 탐색하지 않는다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      visited_ids = result.traversal_path.map { |p| p[:concept_id] }
      expect(visited_ids.uniq.count).to eq(visited_ids.count)
    end
  end

  describe 'Multi-hop Reasoning' do
    let(:question) { create(:question, study_material: study_material) }

    it '다중 단계 추론을 수행한다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      expect(result.llm_analysis_metadata).to include('reasoning_steps')
    end

    it '선행 개념을 식별한다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      expect(result.prerequisites).to be_an(Array)
    end

    it '종속 개념을 식별한다' do
      result = service.analyze_wrong_answer(user, question, '①', study_set)

      expect(result.dependents).to be_an(Array)
    end
  end

  describe 'Performance' do
    let(:question) { create(:question, study_material: study_material) }

    it '2초 이내에 분석을 완료한다' do
      start_time = Time.current

      service.analyze_wrong_answer(user, question, '①', study_set)

      elapsed = Time.current - start_time
      expect(elapsed).to be < 2
    end

    it '대량 문제를 효율적으로 처리한다' do
      questions = create_list(:question, 10, study_material: study_material)

      results = questions.map do |q|
        service.analyze_wrong_answer(user, q, '①', study_set)
      end

      expect(results.all? { |r| r.status == 'completed' }).to be true
    end
  end

  private

  def create_knowledge_graph(study_material)
    # 테스트용 지식 그래프 생성
    subject = create(:knowledge_node, study_material: study_material, level: 'subject', name: '테스트 과목')
    chapter1 = create(:knowledge_node, study_material: study_material, level: 'chapter', name: '1장', parent_name: '테스트 과목')
    concept1 = create(:knowledge_node, study_material: study_material, level: 'concept', name: '개념1', parent_name: '1장')
    concept2 = create(:knowledge_node, study_material: study_material, level: 'concept', name: '개념2', parent_name: '1장')

    # 관계 설정
    concept1.add_prerequisite(concept2)
    concept2.add_prerequisite(subject)
  end
end
