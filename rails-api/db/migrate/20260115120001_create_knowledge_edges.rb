class CreateKnowledgeEdges < ActiveRecord::Migration[7.2]
  def change
    create_table :knowledge_edges do |t|
      t.references :knowledge_node, null: false, foreign_key: true
      t.references :related_node, foreign_key: { to_table: :knowledge_nodes }

      # 관계 유형
      t.string :relationship_type, null: false, index: true
      # prerequisite: 선수 개념 (this is prerequisite for related_node)
      # related_to: 관련 개념
      # part_of: 상위 개념
      # example_of: 예시 관계
      # leads_to: 다음 개념

      # 관계 강도 (0.0 ~ 1.0)
      t.float :weight, default: 0.5

      # 추가 정보
      t.text :reasoning # 관계 형성 이유
      t.json :metadata, default: {} # 추가 메타데이터

      t.boolean :active, default: true, index: true
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [:knowledge_node_id, :related_node_id], unique: true
      t.index [:relationship_type, :weight]
    end
  end
end
