require 'rails_helper'

RSpec.describe 'Knowledge Graph Integration', type: :request do
  let(:user) { create(:user) }
  let(:study_material) { create(:study_material) }
  let(:headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  before do
    # Create study set for user
    study_set = create(:study_set, user: user)
    study_material.update(study_set_id: study_set.id)
  end

  describe 'GET /api/v1/study_materials/:study_material_id/knowledge_graph' do
    let!(:nodes) { create_list(:knowledge_node, 3, study_material: study_material) }

    it 'returns knowledge graph data' do
      get "/api/v1/study_materials/#{study_material.id}/knowledge_graph", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data']).to include('nodes', 'edges', 'stats')
    end
  end

  describe 'GET /api/v1/study_materials/:study_material_id/knowledge_graph/statistics' do
    let!(:nodes) { create_list(:knowledge_node, 5, study_material: study_material) }
    let!(:edges) { create_list(:knowledge_edge, 3, knowledge_node: nodes.first) }

    it 'returns graph statistics' do
      get "/api/v1/study_materials/#{study_material.id}/knowledge_graph/statistics", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      stats = json['data']
      expect(stats['total_nodes']).to eq(5)
      expect(stats['total_edges']).to be > 0
    end
  end

  describe 'GET /api/v1/study_materials/:study_material_id/knowledge_graph/analysis' do
    let(:weak_node) { create(:knowledge_node, study_material: study_material) }
    let(:strong_node) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
      create(:user_mastery, :mastered, user: user, knowledge_node: strong_node)
    end

    it 'returns learning analysis' do
      get "/api/v1/study_materials/#{study_material.id}/knowledge_graph/analysis", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      data = json['data']
      expect(data).to include('weak_areas', 'strong_areas', 'dashboard_summary')
      expect(data['weak_areas'].length).to be > 0
      expect(data['strong_areas'].length).to be > 0
    end
  end

  describe 'GET /api/v1/knowledge_nodes/:id' do
    let(:node) { create(:knowledge_node, study_material: study_material) }

    it 'returns node details' do
      get "/api/v1/knowledge_nodes/#{node.id}", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(node.id)
      expect(json['data']['name']).to eq(node.name)
    end
  end

  describe 'GET /api/v1/knowledge_nodes/:id/prerequisites' do
    let(:node) { create(:knowledge_node, study_material: study_material) }
    let(:prereq) { create(:knowledge_node, study_material: study_material) }

    before do
      node.add_prerequisite(prereq)
    end

    it 'returns prerequisites' do
      get "/api/v1/knowledge_nodes/#{node.id}/prerequisites", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data'].length).to be > 0
      expect(json['data'].first['name']).to eq(prereq.name)
    end
  end

  describe 'GET /api/v1/knowledge_nodes/:knowledge_node_id/mastery' do
    let(:node) { create(:knowledge_node, study_material: study_material) }
    let!(:mastery) { create(:user_mastery, user: user, knowledge_node: node) }

    it 'returns user mastery for node' do
      get "/api/v1/knowledge_nodes/#{node.id}/mastery", headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data']['knowledge_node_id']).to eq(node.id)
      expect(json['data']['mastery_level']).to eq(mastery.mastery_level)
    end
  end

  describe 'PUT /api/v1/knowledge_nodes/:knowledge_node_id/mastery' do
    let(:node) { create(:knowledge_node, study_material: study_material) }

    it 'updates user mastery' do
      put "/api/v1/knowledge_nodes/#{node.id}/mastery",
          params: { attempt: { correct: true, time_minutes: 5 } },
          headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data']['attempts']).to be > 0
    end
  end

  describe 'GET /api/v1/masteries/weak_areas' do
    let!(:weak_node) { create(:knowledge_node, study_material: study_material) }
    let!(:strong_node) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
      create(:user_mastery, :mastered, user: user, knowledge_node: strong_node)
    end

    it 'returns weak areas' do
      get '/api/v1/masteries/weak_areas', headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['color']).to eq('red')
    end
  end

  describe 'GET /api/v1/masteries/strong_areas' do
    let!(:weak_node) { create(:knowledge_node, study_material: study_material) }
    let!(:strong_node) { create(:knowledge_node, study_material: study_material) }

    before do
      create(:user_mastery, :weak, user: user, knowledge_node: weak_node)
      create(:user_mastery, :mastered, user: user, knowledge_node: strong_node)
    end

    it 'returns strong areas' do
      get '/api/v1/masteries/strong_areas', headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['data'].length).to eq(1)
      expect(json['data'].first['color']).to eq('green')
    end
  end

  describe 'GET /api/v1/masteries/statistics' do
    let!(:nodes) { create_list(:knowledge_node, 5, study_material: study_material) }

    before do
      nodes[0..2].each { |n| create(:user_mastery, :mastered, user: user, knowledge_node: n) }
      nodes[3..4].each { |n| create(:user_mastery, :weak, user: user, knowledge_node: n) }
    end

    it 'returns mastery statistics' do
      get '/api/v1/masteries/statistics', headers: headers

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      stats = json['data']
      expect(stats['total_concepts']).to eq(5)
      expect(stats['mastered']).to eq(3)
      expect(stats['weak']).to eq(2)
    end
  end
end
