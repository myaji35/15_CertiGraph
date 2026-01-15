class CreateKnowledgeNodes < ActiveRecord::Migration[7.2]
  def change
    create_table :knowledge_nodes do |t|
      t.references :study_material, null: false, foreign_key: true

      # 기본 정보
      t.string :name, null: false, index: true
      t.text :description

      # 온톨로지 구조
      t.string :level, null: false, default: 'concept' # subject, chapter, concept, detail
      t.string :parent_name, index: true # 계층 구조를 위한 부모 이름

      # 메타데이터
      t.integer :difficulty, default: 3 # 1-5 난이도
      t.integer :importance, default: 3 # 1-5 중요도

      # JSON 저장소 - 벡터, 관계 등
      t.json :metadata, default: {} # 추가 메타데이터

      # 인덱싱 및 조회
      t.boolean :active, default: true, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [:study_material_id, :level]
      t.index [:study_material_id, :parent_name]
    end
  end
end
