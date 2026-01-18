# Knowledge Graph Analysis Controller
class KnowledgeAnalysisController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_set

  # GET /study_sets/:id/knowledge_analysis
  def show
    @study_material = @study_set.study_materials.first
    
    if @study_material.nil?
      redirect_to @study_set, alert: '학습 자료가 없습니다. 먼저 PDF를 업로드해주세요.'
      return
    end

    # 그래프 서비스 초기화
    @graph_service = KnowledgeGraphService.new(@study_material)
    @analysis_service = GraphAnalysisService.new(current_user, @study_material)

    # 통계 데이터
    @stats = @graph_service.graph_statistics
    @progress = @analysis_service.calculate_progress_percentage
    
    # 약점 및 강점 분석
    @weak_areas = @analysis_service.identify_weak_areas.take(5)
    @strong_areas = @analysis_service.identify_strong_areas.take(5)
    
    # 추천 학습 경로
    @recommended_path = @analysis_service.recommend_learning_path(limit: 10)
    
    # 3D 시각화용 데이터
    @concept_map = @analysis_service.generate_concept_map
    
    # 대시보드 요약
    @dashboard_summary = @analysis_service.dashboard_summary
  rescue StandardError => e
    Rails.logger.error "Knowledge Analysis Error: #{e.message}"
    redirect_to @study_set, alert: '지식 그래프 분석 중 오류가 발생했습니다.'
  end

  private

  def set_study_set
    @study_set = StudySet.find(params[:study_set_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to study_sets_path, alert: '문제집을 찾을 수 없습니다.'
  end
end
