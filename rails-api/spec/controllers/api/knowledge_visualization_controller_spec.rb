require 'rails_helper'

RSpec.describe Api::KnowledgeVisualizationController, type: :controller do
  let(:user) { create(:user) }
  let(:study_material) { create(:study_material, user: user) }
  let!(:node1) { create(:knowledge_node, study_material: study_material, name: 'Node 1') }
  let!(:node2) { create(:knowledge_node, study_material: study_material, name: 'Node 2') }
  let!(:edge) { create(:knowledge_edge, knowledge_node: node1, related_node: node2) }

  before do
    sign_in user
  end

  describe 'GET #graph_data' do
    it 'returns graph data successfully' do
      get :graph_data, params: { id: study_material.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']).to have_key('nodes')
      expect(json['data']).to have_key('edges')
      expect(json['data']).to have_key('statistics')
    end

    it 'includes node positions' do
      get :graph_data, params: { id: study_material.id }

      json = JSON.parse(response.body)
      nodes = json['data']['nodes']

      expect(nodes.count).to eq(2)
      nodes.each do |node|
        expect(node['position']).to have_key('x')
        expect(node['position']).to have_key('y')
        expect(node['position']).to have_key('z')
      end
    end

    context 'when study material does not belong to user' do
      let(:other_user) { create(:user) }
      let(:other_study_material) { create(:study_material, user: other_user) }

      it 'returns forbidden status' do
        get :graph_data, params: { id: other_study_material.id }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end

  describe 'GET #node_detail' do
    it 'returns node details successfully' do
      get :node_detail, params: { id: study_material.id, node_id: node1.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['node']['id']).to eq(node1.id)
      expect(json['data']['node']['name']).to eq('Node 1')
    end

    it 'includes mastery information' do
      mastery = create(:user_mastery, user: user, knowledge_node: node1, mastery_level: 0.8)

      get :node_detail, params: { id: study_material.id, node_id: node1.id }

      json = JSON.parse(response.body)
      expect(json['data']['mastery']).to be_present
      expect(json['data']['mastery']['mastery_level']).to eq(0.8)
    end

    it 'includes prerequisites and dependents' do
      get :node_detail, params: { id: study_material.id, node_id: node1.id }

      json = JSON.parse(response.body)
      expect(json['data']).to have_key('prerequisites')
      expect(json['data']).to have_key('dependents')
    end

    context 'when node does not belong to study material' do
      let(:other_study_material) { create(:study_material, user: user) }
      let(:other_node) { create(:knowledge_node, study_material: other_study_material) }

      it 'returns forbidden status' do
        get :node_detail, params: { id: study_material.id, node_id: other_node.id }

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end

    context 'when node does not exist' do
      it 'returns not found status' do
        get :node_detail, params: { id: study_material.id, node_id: 99999 }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json['success']).to be false
      end
    end
  end

  describe 'GET #statistics' do
    before do
      create(:user_mastery, user: user, knowledge_node: node1, color: 'green', mastery_level: 0.9)
      create(:user_mastery, user: user, knowledge_node: node2, color: 'red', mastery_level: 0.3)
    end

    it 'returns statistics successfully' do
      get :statistics, params: { id: study_material.id }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['total_nodes']).to eq(2)
      expect(json['data']['mastered']).to eq(1)
      expect(json['data']['weak']).to eq(1)
    end

    it 'calculates percentages correctly' do
      get :statistics, params: { id: study_material.id }

      json = JSON.parse(response.body)
      expect(json['data']['mastered_percentage']).to eq(50.0)
      expect(json['data']['weak_percentage']).to eq(50.0)
    end
  end

  describe 'POST #filter_nodes' do
    let!(:easy_node) { create(:knowledge_node, study_material: study_material, difficulty: 1, level: 'concept') }
    let!(:hard_node) { create(:knowledge_node, study_material: study_material, difficulty: 5, level: 'detail') }

    it 'filters nodes by difficulty' do
      post :filter_nodes, params: { id: study_material.id, difficulty: 1 }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['success']).to be true
      expect(json['data']['nodes'].count).to eq(1)
      expect(json['data']['nodes'].first['difficulty']).to eq(1)
    end

    it 'filters nodes by level' do
      post :filter_nodes, params: { id: study_material.id, level: 'concept' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      # Should include node1, node2, and easy_node
      expect(json['data']['nodes'].count).to be >= 1
      json['data']['nodes'].each do |node|
        expect(node['level']).to eq('concept')
      end
    end

    it 'filters nodes by mastery color' do
      create(:user_mastery, user: user, knowledge_node: node1, color: 'green')
      create(:user_mastery, user: user, knowledge_node: node2, color: 'red')

      post :filter_nodes, params: { id: study_material.id, color: 'green' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json['data']['nodes'].count).to eq(1)
    end

    it 'returns applied filters in response' do
      post :filter_nodes, params: { id: study_material.id, difficulty: 1, level: 'concept' }

      json = JSON.parse(response.body)
      expect(json['filters_applied']).to include('difficulty' => '1', 'level' => 'concept')
    end
  end

  describe 'authentication' do
    before do
      sign_out user
    end

    it 'requires authentication for graph_data' do
      get :graph_data, params: { id: study_material.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for node_detail' do
      get :node_detail, params: { id: study_material.id, node_id: node1.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for statistics' do
      get :statistics, params: { id: study_material.id }
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'requires authentication for filter_nodes' do
      post :filter_nodes, params: { id: study_material.id }
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
