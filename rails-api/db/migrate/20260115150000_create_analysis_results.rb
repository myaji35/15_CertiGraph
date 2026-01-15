class CreateAnalysisResults < ActiveRecord::Migration[7.2]
  def change
    create_table :analysis_results do |t|
      t.references :user, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.references :study_set, null: false, foreign_key: true

      # 분석 메타데이터
      t.string :analysis_type, null: false # 'wrong_answer', 'learning_gap', 'concept_weakness'
      t.string :status, null: false, default: 'pending' # pending, processing, completed, failed

      # 오답 분석 결과
      t.float :concept_gap_score, default: 0.0 # 0-1: 개념 격차 점수
      t.string :error_type # 'careless', 'concept_gap', 'mixed'
      t.text :error_description # 상세 오답 원인 분석

      # 연관 개념 분석
      t.json :related_concepts # [{concept_id, name, relevance_score, relationship_type}]
      t.json :prerequisite_concepts # 선수 개념 분석
      t.json :dependent_concepts # 종속 개념 분석

      # 그래프 탐색 결과
      t.integer :graph_depth, default: 0 # 탐색한 그래프 깊이
      t.integer :nodes_traversed, default: 0 # 탐색한 노드 수
      t.json :traversal_path # 탐색 경로 기록

      # 추론 결과
      t.text :llm_reasoning # LLM 추론 결과
      t.json :llm_analysis_metadata # LLM 분석 상세 정보

      # 강도 점수 (0-1)
      t.float :confidence_score, default: 0.0 # 분석 신뢰도

      # 학습 경로 추천
      t.json :recommended_learning_path # 추천된 학습 경로

      # 처리 시간 (성능 모니터링용)
      t.integer :processing_time_ms, default: 0

      # 에러 처리
      t.text :error_message
      t.text :error_backtrace

      t.timestamps
    end

    add_index :analysis_results, %i[user_id study_set_id status], name: 'idx_analysis_results_user_study_status'
    add_index :analysis_results, %i[analysis_type status], name: 'idx_analysis_results_type_status'
    add_index :analysis_results, :concept_gap_score
    add_index :analysis_results, :created_at
  end
end
