class CreateLearningRecommendations < ActiveRecord::Migration[7.2]
  def change
    create_table :learning_recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_set, null: false, foreign_key: true
      t.references :analysis_result, null: true, foreign_key: true

      # 추천 메타데이터
      t.string :recommendation_type, null: false # 'remedial', 'progressive', 'comprehensive'
      t.string :status, null: false, default: 'pending' # pending, active, completed, dismissed

      # 추천 문제 그룹
      t.json :recommended_questions # [{ question_id, priority, reason }]
      t.integer :total_recommended_count, default: 0

      # 우선순위 및 난이도 조정
      t.integer :priority_level, default: 5 # 1-10: 높을수록 중요
      t.integer :suggested_difficulty # 추천 난이도 레벨
      t.float :difficulty_adjustment_ratio, default: 1.0 # 1.0 = normal

      # 약점 분석
      t.json :weakness_analysis # { concept_gaps: [], error_patterns: [], mastery_predictions: [] }
      t.json :concept_mastery_map # 개념별 숙달도 맵

      # 학습 경로
      t.json :learning_path # 단계별 학습 경로 정의
      t.integer :estimated_learning_hours, default: 0

      # 개인화 파라미터
      t.json :personalization_params # { learning_style, pace, concentration_level }
      t.json :adaptive_params # 적응형 학습 파라미터

      # 효율성 지표
      t.float :learning_efficiency_index, default: 0.0 # 0-1: 학습 효율성
      t.float :success_probability, default: 0.0 # 0-1: 성공 확률 예측
      t.float :time_efficiency, default: 0.0 # 예상 학습 시간 효율성

      # 활동 추적
      t.datetime :started_at
      t.datetime :completed_at
      t.json :progress_tracking # { questions_completed, accuracy, time_spent }

      # 피드백 및 조정
      t.text :user_feedback
      t.boolean :is_accepted, default: false
      t.integer :feedback_rating # 1-5: 추천 품질 평가

      t.timestamps
    end

    add_index :learning_recommendations, %i[user_id study_set_id status], name: 'idx_recommendations_user_study_status'
    add_index :learning_recommendations, %i[recommendation_type status], name: 'idx_recommendations_type_status'
    add_index :learning_recommendations, :priority_level
    add_index :learning_recommendations, :created_at
    add_index :learning_recommendations, :learning_efficiency_index
  end
end
