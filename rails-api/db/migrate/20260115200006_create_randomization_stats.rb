class CreateRandomizationStats < ActiveRecord::Migration[7.2]
  def change
    create_table :randomization_stats do |t|
      t.references :study_material, null: false, foreign_key: true
      t.references :question, null: false, foreign_key: true
      t.integer :option_id, null: false
      t.string :option_label, null: false # ①, ②, ③, ④, ⑤
      t.integer :position_0_count, default: 0
      t.integer :position_1_count, default: 0
      t.integer :position_2_count, default: 0
      t.integer :position_3_count, default: 0
      t.integer :position_4_count, default: 0
      t.integer :total_randomizations, default: 0
      t.float :chi_square_statistic, default: 0.0
      t.float :p_value, default: 1.0
      t.float :bias_score, default: 0.0 # 0-100, lower is better
      t.boolean :is_uniform, default: true
      t.json :position_distribution # { "0": 20, "1": 18, "2": 22, "3": 21, "4": 19 }
      t.json :analysis_metadata
      t.datetime :last_analyzed_at

      t.timestamps
    end

    add_index :randomization_stats, [:study_material_id, :question_id], name: 'idx_rand_stats_material_question'
    add_index :randomization_stats, :option_id
    add_index :randomization_stats, :chi_square_statistic
    add_index :randomization_stats, :bias_score
    add_index :randomization_stats, :is_uniform
  end
end
