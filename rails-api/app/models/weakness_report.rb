class WeaknessReport < ApplicationRecord
  belongs_to :user
  belongs_to :study_material, optional: true

  validates :report_type, presence: true, inclusion: {
    in: %w[comprehensive weekly monthly exam_specific]
  }

  # Scopes
  scope :by_type, ->(type) { where(report_type: type) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_period, ->(start_date, end_date) {
    where('period_start >= ? AND period_end <= ?', start_date, end_date)
  }

  # PDF generation
  def generate_pdf!
    return if pdf_status == 'ready'

    update!(pdf_status: 'generating')

    begin
      # This would integrate with a PDF generation service
      # For now, we'll just mark it as ready with a placeholder URL
      pdf_path = generate_pdf_content

      update!(
        pdf_status: 'ready',
        pdf_url: pdf_path,
        pdf_generated_at: Time.current
      )
    rescue StandardError => e
      update!(
        pdf_status: 'failed',
        metadata: metadata.merge(pdf_error: e.message)
      )
      raise
    end
  end

  # Analysis methods
  def calculate_overall_weakness_score
    return 0 if weakness_by_concept.blank?

    total_severity = weakness_by_concept.values.sum { |w| w['severity'] || 0 }
    concept_count = weakness_by_concept.count

    (total_severity.to_f / concept_count).round

    end

  def identify_critical_weaknesses(limit = 5)
    return [] if weakness_by_concept.blank?

    weaknesses = weakness_by_concept.map do |concept_id, data|
      {
        concept_id: concept_id,
        severity: data['severity'] || 0,
        concept_name: data['concept_name'] || 'Unknown',
        attempts: data['attempts'] || 0,
        accuracy: data['accuracy'] || 0
      }
    end

    weaknesses.sort_by { |w| -w[:severity] }.take(limit)
  end

  def calculate_improvement_percentage
    return 0 if improvement_over_time.blank?

    timeline = improvement_over_time.values.sort_by { |v| v['period'] }
    return 0 if timeline.length < 2

    first_score = timeline.first['score'] || 0
    last_score = timeline.last['score'] || 0

    return 0 if first_score.zero?

    ((last_score - first_score).to_f / first_score * 100).round
  end

  private

  def generate_pdf_content
    # Placeholder for PDF generation
    # In production, this would use a gem like Prawn or WickedPDF
    filename = "weakness_report_#{user.id}_#{Time.current.to_i}.pdf"
    "/reports/#{filename}"
  end
end
