class CreateWeaknessReports < ActiveRecord::Migration[7.2]
  def change
    create_table :weakness_reports do |t|
      t.references :user, null: false, foreign_key: true
      t.references :study_material, foreign_key: true

      # Report metadata
      t.string :report_type, default: 'comprehensive' # 'comprehensive', 'weekly', 'monthly', 'exam_specific'
      t.date :period_start
      t.date :period_end
      t.string :status, default: 'generated' # 'generated', 'sent', 'viewed'

      # Multi-dimensional weakness analysis
      t.json :weakness_by_concept, default: {} # { concept_id: { severity: 0-100, ... } }
      t.json :weakness_by_difficulty, default: {}
      t.json :weakness_by_question_type, default: {}
      t.json :weakness_by_topic, default: {}

      # Severity scores (0-100)
      t.integer :overall_weakness_score, default: 0
      t.json :critical_weaknesses, default: [] # Top 5 most critical
      t.json :moderate_weaknesses, default: []
      t.json :minor_weaknesses, default: []

      # Improvement tracking
      t.json :improvement_over_time, default: {} # Weekly/monthly trends
      t.integer :improvement_percentage
      t.json :improvement_by_concept, default: {}

      # Comparative analysis
      t.json :peer_comparison, default: {} # Compare with similar users
      t.integer :percentile_rank

      # Recommendations
      t.json :priority_recommendations, default: []
      t.json :learning_path_suggestions, default: []
      t.integer :estimated_study_hours

      # Visualization data
      t.json :heatmap_data, default: {}
      t.json :trend_chart_data, default: {}
      t.json :comparison_chart_data, default: {}

      # PDF generation
      t.string :pdf_status, default: 'pending' # 'pending', 'generating', 'ready', 'failed'
      t.string :pdf_url
      t.datetime :pdf_generated_at

      # Metadata
      t.json :statistics, default: {}
      t.json :metadata, default: {}

      t.timestamps
    end

    add_index :weakness_reports, [:user_id, :report_type]
    add_index :weakness_reports, :period_start
    add_index :weakness_reports, :overall_weakness_score
    add_index :weakness_reports, :status
  end
end
