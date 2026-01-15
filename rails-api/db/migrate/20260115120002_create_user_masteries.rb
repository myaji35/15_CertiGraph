class CreateUserMasteries < ActiveRecord::Migration[7.2]
  def change
    create_table :user_masteries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :knowledge_node, null: false, foreign_key: true

      # 숙달도 (0.0 ~ 1.0)
      t.float :mastery_level, default: 0.0

      # 상태
      t.string :status, default: 'untested' # untested, learning, mastered, weak
      t.string :color, default: 'gray' # gray, green, red, yellow

      # 학습 통계
      t.integer :attempts, default: 0
      t.integer :correct_attempts, default: 0
      t.integer :last_tested_days_ago, default: nil

      # 시간 추적
      t.integer :total_time_minutes, default: 0
      t.datetime :last_tested_at

      # JSON - 상세 기록
      t.json :history, default: [] # 시도 기록 배열
      t.json :metadata, default: {}

      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false

      t.index [:user_id, :knowledge_node_id], unique: true
      t.index [:user_id, :status]
      t.index [:user_id, :mastery_level]
      t.index :color
      t.index :status
    end
  end
end
