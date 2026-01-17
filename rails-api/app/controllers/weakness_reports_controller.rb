class WeaknessReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_weakness_report, only: [:show, :generate_pdf, :download_pdf]

  # GET /weakness_reports
  def index
    @reports = current_user.weakness_reports.order(created_at: :desc)

    if params[:report_type]
      @reports = @reports.where(report_type: params[:report_type])
    end

    render json: {
      success: true,
      reports: @reports.map { |report| format_report(report) }
    }
  end

  # GET /weakness_reports/:id
  def show
    render json: {
      success: true,
      report: format_report_detailed(@report)
    }
  end

  # POST /weakness_reports
  def create
    study_material = params[:study_material_id] ? StudyMaterial.find(params[:study_material_id]) : nil

    analyzer = AdvancedWeaknessAnalyzer.new(current_user, study_material)

    @report = analyzer.generate_report(
      report_type: params[:report_type] || 'comprehensive'
    )

    render json: {
      success: true,
      report: format_report_detailed(@report),
      message: 'Weakness report generated successfully'
    }, status: :created
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to generate report: #{e.message}"
    }, status: :unprocessable_entity
  end

  # POST /weakness_reports/:id/generate_pdf
  def generate_pdf
    @report.generate_pdf!

    render json: {
      success: true,
      report: format_report(@report),
      message: 'PDF generation started'
    }
  rescue StandardError => e
    render json: {
      success: false,
      message: "PDF generation failed: #{e.message}"
    }, status: :unprocessable_entity
  end

  # GET /weakness_reports/:id/download_pdf
  def download_pdf
    if @report.pdf_status == 'ready'
      # In production, this would redirect to the actual PDF URL
      render json: {
        success: true,
        pdf_url: @report.pdf_url,
        generated_at: @report.pdf_generated_at
      }
    else
      render json: {
        success: false,
        message: "PDF not ready. Status: #{@report.pdf_status}"
      }, status: :unprocessable_entity
    end
  end

  private

  def set_weakness_report
    @report = current_user.weakness_reports.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'Weakness report not found'
    }, status: :not_found
  end

  def format_report(report)
    {
      id: report.id,
      report_type: report.report_type,
      period_start: report.period_start,
      period_end: report.period_end,
      overall_weakness_score: report.overall_weakness_score,
      improvement_percentage: report.improvement_percentage,
      percentile_rank: report.percentile_rank,
      pdf_status: report.pdf_status,
      pdf_url: report.pdf_url,
      created_at: report.created_at
    }
  end

  def format_report_detailed(report)
    format_report(report).merge(
      weakness_by_concept: report.weakness_by_concept,
      weakness_by_difficulty: report.weakness_by_difficulty,
      weakness_by_topic: report.weakness_by_topic,
      critical_weaknesses: report.critical_weaknesses,
      moderate_weaknesses: report.moderate_weaknesses,
      improvement_over_time: report.improvement_over_time,
      peer_comparison: report.peer_comparison,
      priority_recommendations: report.priority_recommendations,
      learning_path_suggestions: report.learning_path_suggestions,
      estimated_study_hours: report.estimated_study_hours,
      heatmap_data: report.heatmap_data,
      trend_chart_data: report.trend_chart_data,
      comparison_chart_data: report.comparison_chart_data,
      statistics: report.statistics
    )
  end
end
