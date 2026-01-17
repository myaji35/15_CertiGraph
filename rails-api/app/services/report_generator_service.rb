# app/services/report_generator_service.rb
require 'csv'
require 'prawn' # Would need to add 'prawn' gem to Gemfile

class ReportGeneratorService
  def initialize(user)
    @user = user
    @analytics = ProgressAnalyticsService.new(user)
    @chart_service = ChartDataService.new(user)
  end

  # Generate PDF report
  def generate_pdf_report(period = 'month')
    # Note: This requires the 'prawn' gem
    # Add to Gemfile: gem 'prawn'
    #
    # For now, returning a placeholder message
    # In production, this would use Prawn to generate a formatted PDF

    report_data = compile_report_data(period)

    # Placeholder - would use Prawn::Document.new to create PDF
    pdf_content = generate_pdf_with_prawn(report_data)

    pdf_content
  end

  # Generate CSV report
  def generate_csv_report(period = 'month')
    report_data = compile_report_data(period)

    CSV.generate(headers: true) do |csv|
      # Header
      csv << ['CertiGraph Dashboard Report']
      csv << ["Period: #{period}"]
      csv << ["Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S')}"]
      csv << []

      # Overview Statistics
      csv << ['OVERVIEW STATISTICS']
      csv << ['Metric', 'Value']
      overview = report_data[:overview]
      csv << ['Total Study Sets', overview[:total_study_sets]]
      csv << ['Total Test Sessions', overview[:total_test_sessions]]
      csv << ['Completed Tests', overview[:completed_tests]]
      csv << ['Average Score', "#{overview[:average_score]}%"]
      csv << ['Total Study Time (hours)', overview[:total_study_time]]
      csv << ['Current Streak (days)', overview[:streak_days]]
      csv << ['Recent Improvement', "#{overview[:recent_improvement]}%"]
      csv << []

      # Mastery Overview
      csv << ['MASTERY OVERVIEW']
      csv << ['Status', 'Count']
      mastery = overview[:mastery_overview]
      csv << ['Mastered', mastery[:mastered]]
      csv << ['Learning', mastery[:learning]]
      csv << ['Weak', mastery[:weak]]
      csv << ['Untested', mastery[:untested]]
      csv << []

      # Progress by Study Set
      csv << ['PROGRESS BY STUDY SET']
      csv << ['Study Set', 'Total Concepts', 'Mastered', 'Progress %']
      report_data[:progress][:progress_by_study_set].each do |study_set|
        csv << [
          study_set[:title],
          study_set[:total_concepts],
          study_set[:mastered],
          study_set[:progress_percentage]
        ]
      end
      csv << []

      # Recent Activity
      csv << ['RECENT ACTIVITY']
      csv << ['Date', 'Type', 'Action', 'Details']
      report_data[:recent_activity].each do |activity|
        csv << [
          activity[:timestamp].strftime('%Y-%m-%d %H:%M'),
          activity[:type],
          activity[:action],
          activity[:details].to_json
        ]
      end
      csv << []

      # Learning Patterns
      csv << ['LEARNING PATTERNS']
      patterns = report_data[:learning_patterns]
      csv << ['Average Session Duration (min)', patterns[:average_session_duration]]
      csv << ['Questions Per Session', patterns[:questions_per_session]]
      csv << ['Concept Mastery Rate', "#{patterns[:concept_mastery_rate][:mastery_rate]}%"]
      csv << []

      # Preferred Study Times
      csv << ['PREFERRED STUDY TIMES']
      csv << ['Hour', 'Session Count']
      patterns[:preferred_study_times].each do |time|
        csv << [time[:hour], time[:count]]
      end
      csv << []

      # Weak Areas
      csv << ['WEAK AREAS']
      csv << ['Concept', 'Mastery Level', 'Attempts']
      patterns[:weak_areas].each do |area|
        csv << [area[:concept], area[:mastery_level], area[:attempts]]
      end
      csv << []

      # Achievements
      csv << ['ACHIEVEMENTS']
      csv << ['Name', 'Description']
      report_data[:achievements][:badges].each do |badge|
        csv << [badge[:name], badge[:description]]
      end
    end
  end

  # Generate JSON report
  def generate_json_report(period = 'month')
    compile_report_data(period).to_json
  end

  # Generate HTML report
  def generate_html_report(period = 'month')
    report_data = compile_report_data(period)

    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Dashboard Report - #{@user.email}</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
          }
          .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 20px;
          }
          .section {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
          .metric {
            display: inline-block;
            margin: 10px 20px;
            text-align: center;
          }
          .metric-value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
          }
          .metric-label {
            color: #666;
            margin-top: 5px;
          }
          table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
          }
          th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
          }
          th {
            background-color: #f8f9fa;
            font-weight: bold;
          }
          .badge {
            background-color: #4CAF50;
            color: white;
            padding: 5px 10px;
            border-radius: 20px;
            display: inline-block;
            margin: 5px;
          }
          .chart-placeholder {
            background: #f0f0f0;
            height: 300px;
            display: flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            color: #666;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Dashboard Report</h1>
          <p>User: #{@user.email}</p>
          <p>Period: #{period.capitalize}</p>
          <p>Generated: #{Time.current.strftime('%B %d, %Y at %I:%M %p')}</p>
        </div>

        <div class="section">
          <h2>Overview Statistics</h2>
          <div class="metric">
            <div class="metric-value">#{report_data[:overview][:total_test_sessions]}</div>
            <div class="metric-label">Test Sessions</div>
          </div>
          <div class="metric">
            <div class="metric-value">#{report_data[:overview][:average_score]}%</div>
            <div class="metric-label">Average Score</div>
          </div>
          <div class="metric">
            <div class="metric-value">#{report_data[:overview][:total_study_time]}h</div>
            <div class="metric-label">Study Time</div>
          </div>
          <div class="metric">
            <div class="metric-value">#{report_data[:overview][:streak_days]}</div>
            <div class="metric-label">Day Streak</div>
          </div>
        </div>

        <div class="section">
          <h2>Mastery Distribution</h2>
          <table>
            <tr>
              <th>Status</th>
              <th>Count</th>
              <th>Percentage</th>
            </tr>
            #{mastery_rows(report_data[:overview][:mastery_overview])}
          </table>
        </div>

        <div class="section">
          <h2>Progress by Study Set</h2>
          <table>
            <tr>
              <th>Study Set</th>
              <th>Total Concepts</th>
              <th>Mastered</th>
              <th>Progress</th>
            </tr>
            #{progress_rows(report_data[:progress][:progress_by_study_set])}
          </table>
        </div>

        <div class="section">
          <h2>Learning Patterns</h2>
          <p><strong>Average Session Duration:</strong> #{report_data[:learning_patterns][:average_session_duration]} minutes</p>
          <p><strong>Questions Per Session:</strong> #{report_data[:learning_patterns][:questions_per_session]}</p>
          <p><strong>Mastery Rate:</strong> #{report_data[:learning_patterns][:concept_mastery_rate][:mastery_rate]}%</p>
        </div>

        <div class="section">
          <h2>Achievements</h2>
          #{achievement_badges(report_data[:achievements][:badges])}
        </div>

        <div class="section">
          <h2>Weak Areas (Focus Needed)</h2>
          <table>
            <tr>
              <th>Concept</th>
              <th>Mastery Level</th>
              <th>Attempts</th>
            </tr>
            #{weak_area_rows(report_data[:learning_patterns][:weak_areas])}
          </table>
        </div>
      </body>
      </html>
    HTML

    html
  end

  private

  def compile_report_data(period)
    stats = case period
            when 'day'
              @analytics.daily_stats
            when 'week'
              @analytics.weekly_stats
            when 'month'
              @analytics.monthly_stats
            when 'year'
              @analytics.yearly_stats
            else
              @analytics.monthly_stats
            end

    {
      period: period,
      generated_at: Time.current,
      user: {
        email: @user.email,
        id: @user.id
      },
      overview: @analytics.overview,
      progress: @analytics.overall_progress,
      learning_patterns: @analytics.learning_patterns,
      achievements: @analytics.calculate_achievements,
      recent_activity: @analytics.recent_activity(20),
      period_stats: stats
    }
  end

  def generate_pdf_with_prawn(report_data)
    # This is a placeholder - in production would use Prawn
    # Example:
    #
    # Prawn::Document.new do |pdf|
    #   pdf.text "Dashboard Report", size: 30, style: :bold
    #   pdf.move_down 20
    #   pdf.text "User: #{@user.email}"
    #   pdf.text "Generated: #{Time.current}"
    #   # ... add more content
    # end.render

    "PDF generation requires 'prawn' gem. Please add to Gemfile: gem 'prawn'\n\n" +
    "Report Data:\n" +
    JSON.pretty_generate(report_data)
  end

  def mastery_rows(mastery_overview)
    total = mastery_overview.values.sum
    return '<tr><td colspan="3">No data available</td></tr>' if total.zero?

    mastery_overview.map do |status, count|
      percentage = ((count.to_f / total) * 100).round(1)
      "<tr><td>#{status.to_s.capitalize}</td><td>#{count}</td><td>#{percentage}%</td></tr>"
    end.join
  end

  def progress_rows(progress_by_study_set)
    return '<tr><td colspan="4">No study sets available</td></tr>' if progress_by_study_set.empty?

    progress_by_study_set.map do |study_set|
      <<~ROW
        <tr>
          <td>#{study_set[:title]}</td>
          <td>#{study_set[:total_concepts]}</td>
          <td>#{study_set[:mastered]}</td>
          <td>#{study_set[:progress_percentage]}%</td>
        </tr>
      ROW
    end.join
  end

  def achievement_badges(badges)
    return '<p>No achievements yet</p>' if badges.empty?

    badges.map do |badge|
      "<span class='badge'>#{badge[:name]}: #{badge[:description]}</span>"
    end.join
  end

  def weak_area_rows(weak_areas)
    return '<tr><td colspan="3">No weak areas identified</td></tr>' if weak_areas.empty?

    weak_areas.map do |area|
      <<~ROW
        <tr>
          <td>#{area[:concept]}</td>
          <td>#{area[:mastery_level]}</td>
          <td>#{area[:attempts]}</td>
        </tr>
      ROW
    end.join
  end
end
