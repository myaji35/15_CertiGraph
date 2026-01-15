require 'rails_helper'

RSpec.describe GraphAnalysisService, type: :service do
  let(:user) { create(:user) }
  let(:study_material) { create(:study_material) }
  let(:service) { described_class.new(user, study_material) }

  describe '#identify_weak_areas' do
    let(:node) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, :weak, user: user, knowledge_node: node)
    end

    it 'returns weak areas' do
      weak_areas = service.identify_weak_areas

      expect(weak_areas).to be_an(Array)
      expect(weak_areas.first[:node]).to eq(node)
      expect(weak_areas.first[:mastery_level]).to be < 0.5
    end
  end

  describe '#identify_strong_areas' do
    let(:node) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, :mastered, user: user, knowledge_node: node)
    end

    it 'returns strong areas' do
      strong_areas = service.identify_strong_areas

      expect(strong_areas).to be_an(Array)
      expect(strong_areas.first[:node]).to eq(node)
      expect(strong_areas.first[:mastery_level]).to be > 0.8
    end
  end

  describe '#recommend_learning_path' do
    let!(:weak_node) { create(:knowledge_node, study_material: study_material, importance: 5) }
    let!(:prereq_node) { create(:knowledge_node, study_material: study_material, importance: 4) }

    before do
      weak_node.add_prerequisite(prereq_node)
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
    end

    it 'recommends learning path' do
      path = service.recommend_learning_path(limit: 5)

      expect(path).to be_an(Array)
      # Should include prerequisites of weak areas
      expect(path).to include(prereq_node) if path.any?
    end
  end

  describe '#calculate_progress_percentage' do
    let!(:nodes) { create_list(:knowledge_node, 5, study_material: study_material) }

    before do
      nodes[0..2].each { |n| create(:user_mastery, :mastered, user: user, knowledge_node: n) }
      nodes[3..4].each { |n| create(:user_mastery, :weak, user: user, knowledge_node: n) }
    end

    it 'calculates progress percentage' do
      progress = service.calculate_progress_percentage

      expect(progress).to eq(60.0) # 3 out of 5 mastered
    end
  end

  describe '#calculate_overall_difficulty' do
    before do
      create(:knowledge_node, study_material: study_material, difficulty: 1, importance: 1)
      create(:knowledge_node, study_material: study_material, difficulty: 5, importance: 5)
    end

    it 'calculates weighted average difficulty' do
      difficulty = service.calculate_overall_difficulty

      expect(difficulty).to be_between(1, 5)
    end
  end

  describe '#estimate_study_time_needed' do
    let(:node) { create(:knowledge_node, study_material: study_material, difficulty: 3) }
    let!(:mastery) { create(:user_mastery, user: user, knowledge_node: node, correct_attempts: 5, attempts: 10) }

    it 'estimates study time' do
      time = service.estimate_study_time_needed(node)

      expect(time).to be > 0
    end
  end

  describe '#identify_review_needed' do
    let!(:node1) { create(:knowledge_node, study_material: study_material) }
    let!(:node2) { create(:knowledge_node, study_material: study_material) }
    let!(:node3) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, user: user, knowledge_node: node1, last_tested_at: 10.days.ago, correct_attempts: 1, attempts: 10)
      create(:user_mastery, user: user, knowledge_node: node2, last_tested_at: 2.days.ago, correct_attempts: 9, attempts: 10)
      create(:user_mastery, user: user, knowledge_node: node3, last_tested_at: 1.day.ago)
    end

    it 'identifies concepts needing review' do
      review_needed = service.identify_review_needed(days: 7)

      expect(review_needed).to include(node1) # Tested > 7 days ago
    end
  end

  describe '#dashboard_summary' do
    before do
      weak_node = create(:knowledge_node, study_material: study_material)
      strong_node = create(:knowledge_node, study_material: study_material)

      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
      create(:user_mastery, :mastered, user: user, knowledge_node: strong_node)
    end

    it 'returns dashboard summary' do
      summary = service.dashboard_summary

      expect(summary).to include(
        :progress_percentage,
        :weak_areas_count,
        :strong_areas_count,
        :recommended_path,
        :review_needed,
        :overall_difficulty,
        :recent_activity
      )
    end
  end

  describe '#suggest_learning_strategy' do
    let(:weak_node) { create(:knowledge_node, study_material: study_material) }
    let(:prereq_node) { create(:knowledge_node, study_material: study_material) }

    before do
      weak_node.add_prerequisite(prereq_node)
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
    end

    it 'suggests learning strategy' do
      strategy = service.suggest_learning_strategy

      expect(strategy).to include(
        :focus_area,
        :current_mastery,
        :blocker_concepts,
        :next_steps,
        :estimated_time_hours
      )
    end
  end

  describe '#analyze_dependency_chains' do
    let(:weak_node) { create(:knowledge_node, study_material: study_material) }
    let(:prereq1) { create(:knowledge_node, study_material: study_material) }
    let(:prereq2) { create(:knowledge_node, study_material: study_material) }

    before do
      weak_node.add_prerequisite(prereq1)
      prereq1.add_prerequisite(prereq2)
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
    end

    it 'analyzes dependency chains' do
      chains = service.analyze_dependency_chains

      expect(chains).to be_a(Hash)
      expect(chains[weak_node.name]).to include(:prerequisites, :blocker)
    end
  end

  describe '#generate_concept_map' do
    before do
      create_list(:knowledge_node, 5, study_material: study_material)
      create_list(:knowledge_edge, 3, knowledge_node: KnowledgeNode.first)
    end

    it 'generates concept map' do
      map = service.generate_concept_map

      expect(map).to include(:nodes, :edges, :layout)
      expect(map[:nodes]).to be_an(Array)
      expect(map[:edges]).to be_an(Array)
    end
  end
end
