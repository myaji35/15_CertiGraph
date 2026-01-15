class AnalyzeLearningGapsJob
  include Sidekiq::Job

  sidekiq_options retry: 3

  def perform(user_id, study_material_id)
    user = User.find(user_id)
    study_material = StudyMaterial.find(study_material_id)

    service = GraphAnalysisService.new(user, study_material)

    # 약점 분석
    weak_areas = service.identify_weak_areas
    strong_areas = service.identify_strong_areas

    # 학습 경로 추천
    recommended_path = service.recommend_learning_path(limit: 10)

    # 의존성 분석
    dependency_chains = service.analyze_dependency_chains

    # 학습 전략 제시
    learning_strategy = service.suggest_learning_strategy

    # 결과 저장 (필요시 별도 테이블)
    store_analysis_results(user, study_material, {
      weak_areas: weak_areas.length,
      strong_areas: strong_areas.length,
      recommended_path: recommended_path.map(&:name),
      dependency_chains: dependency_chains,
      learning_strategy: learning_strategy
    })

    Rails.logger.info("Learning gaps analyzed for user #{user_id}, material #{study_material_id}")
  rescue => e
    Rails.logger.error("AnalyzeLearningGapsJob failed: #{e.message}")
    raise e
  end

  private

  def store_analysis_results(user, study_material, results)
    # 분석 결과 저장 (예: Redis 캐시 또는 별도 DB)
    cache_key = "learning_analysis:#{user.id}:#{study_material.id}"
    Rails.cache.write(cache_key, results, expires_in: 24.hours)
  end
end
