module Api
  module V1
    class PerformanceController < ApplicationController
      before_action :authenticate_user!
      before_action :set_study_set, only: [
        :comprehensive_report, :quick_summary, :subject_breakdown,
        :time_analysis, :predictions, :chart_data
      ]

      # GET /api/v1/performance/comprehensive_report
      # Full comprehensive performance report
      def comprehensive_report
        service = PerformanceReportService.new(
          current_user,
          study_set: @study_set,
          start_date: parse_date(params[:start_date], 30.days.ago),
          end_date: parse_date(params[:end_date], Date.today)
        )

        report = service.generate_report

        render json: {
          status: 'success',
          data: report
        }
      rescue StandardError => e
        render json: {
          status: 'error',
          message: e.message
        }, status: :internal_server_error
      end

      # GET /api/v1/performance/quick_summary
      # Quick dashboard summary
      def quick_summary
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        summary = service.quick_summary

        render json: {
          status: 'success',
          data: summary
        }
      end

      # GET /api/v1/performance/subject_breakdown
      # Subject-level performance breakdown
      def subject_breakdown
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        breakdown = service.subject_breakdown

        render json: {
          status: 'success',
          data: breakdown
        }
      end

      # GET /api/v1/performance/chapter_breakdown
      # Chapter-level performance breakdown
      def chapter_breakdown
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        breakdown = service.chapter_breakdown

        render json: {
          status: 'success',
          data: breakdown
        }
      end

      # GET /api/v1/performance/concept_analysis
      # Detailed concept-level analysis
      def concept_analysis
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        analysis = service.concept_analysis

        render json: {
          status: 'success',
          data: analysis
        }
      end

      # GET /api/v1/performance/strengths_weaknesses
      # Top strengths and weaknesses
      def strengths_weaknesses
        service = PerformanceReportService.new(current_user, study_set: @study_set)

        data = {
          strengths: service.top_strengths(limit: params[:limit]&.to_i || 10),
          weaknesses: service.top_weaknesses(limit: params[:limit]&.to_i || 10),
          improvements: service.recent_improvements(
            days: params[:days]&.to_i || 7,
            limit: params[:limit]&.to_i || 10
          )
        }

        render json: {
          status: 'success',
          data: data
        }
      end

      # GET /api/v1/performance/time_analysis
      # Time-based performance analysis
      def time_analysis
        service = TimeBasedAnalysisService.new(
          current_user,
          study_set: @study_set,
          start_date: parse_date(params[:start_date], 30.days.ago),
          end_date: parse_date(params[:end_date], Date.today)
        )

        analysis = service.analyze

        render json: {
          status: 'success',
          data: analysis
        }
      end

      # GET /api/v1/performance/daily_patterns
      # Daily performance patterns
      def daily_patterns
        service = TimeBasedAnalysisService.new(
          current_user,
          study_set: @study_set,
          start_date: parse_date(params[:start_date], 30.days.ago),
          end_date: parse_date(params[:end_date], Date.today)
        )

        patterns = service.daily_patterns

        render json: {
          status: 'success',
          data: patterns
        }
      end

      # GET /api/v1/performance/weekly_patterns
      # Weekly performance patterns
      def weekly_patterns
        service = TimeBasedAnalysisService.new(
          current_user,
          study_set: @study_set,
          start_date: parse_date(params[:start_date], 12.weeks.ago),
          end_date: parse_date(params[:end_date], Date.today)
        )

        patterns = service.weekly_patterns

        render json: {
          status: 'success',
          data: patterns
        }
      end

      # GET /api/v1/performance/time_of_day
      # Time of day analysis
      def time_of_day
        service = TimeBasedAnalysisService.new(current_user, study_set: @study_set)
        analysis = service.time_of_day_analysis

        render json: {
          status: 'success',
          data: analysis
        }
      end

      # GET /api/v1/performance/consistency
      # Study consistency metrics
      def consistency
        service = TimeBasedAnalysisService.new(
          current_user,
          study_set: @study_set,
          start_date: parse_date(params[:start_date], 30.days.ago),
          end_date: parse_date(params[:end_date], Date.today)
        )

        metrics = service.consistency_metrics

        render json: {
          status: 'success',
          data: metrics
        }
      end

      # GET /api/v1/performance/predictions
      # Performance predictions
      def predictions
        service = PerformancePredictorService.new(current_user, study_set: @study_set)
        predictions = service.predict_performance

        render json: {
          status: 'success',
          data: predictions
        }
      end

      # GET /api/v1/performance/exam_score_prediction
      # Exam score prediction
      def exam_score_prediction
        service = PerformancePredictorService.new(current_user, study_set: @study_set)
        prediction = service.predict_exam_score

        render json: {
          status: 'success',
          data: prediction
        }
      end

      # GET /api/v1/performance/mastery_timeline
      # Timeline to achieve target mastery
      def mastery_timeline
        target = params[:target_mastery]&.to_f || 0.8

        service = PerformancePredictorService.new(current_user, study_set: @study_set)
        timeline = service.predict_mastery_timeline(target_mastery: target)

        render json: {
          status: 'success',
          data: timeline
        }
      end

      # GET /api/v1/performance/goal_achievement
      # Goal achievement prediction
      def goal_achievement
        target_score = params[:target_score]&.to_f || 80
        target_date = params[:target_date] ? Date.parse(params[:target_date]) : nil

        service = PerformancePredictorService.new(current_user, study_set: @study_set)
        achievement = service.predict_goal_achievement(
          target_score: target_score,
          target_date: target_date
        )

        render json: {
          status: 'success',
          data: achievement
        }
      end

      # GET /api/v1/performance/risk_assessment
      # Risk assessment
      def risk_assessment
        service = PerformancePredictorService.new(current_user, study_set: @study_set)
        risks = service.assess_risks

        render json: {
          status: 'success',
          data: risks
        }
      end

      # GET /api/v1/performance/snapshots
      # Get performance snapshots
      def snapshots
        snapshots = PerformanceSnapshot
          .where(user_id: current_user.id)
          .where(study_set_id: params[:study_set_id])
          .where(period_type: params[:period] || 'daily')
          .where('snapshot_date >= ?', parse_date(params[:start_date], 30.days.ago))
          .where('snapshot_date <= ?', parse_date(params[:end_date], Date.today))
          .order(snapshot_date: :desc)

        render json: {
          status: 'success',
          data: snapshots.as_json
        }
      end

      # GET /api/v1/performance/snapshot/:id
      # Get single snapshot
      def snapshot
        snapshot = PerformanceSnapshot.find(params[:id])

        if snapshot.user_id != current_user.id
          return render json: {
            status: 'error',
            message: 'Unauthorized'
          }, status: :unauthorized
        end

        render json: {
          status: 'success',
          data: snapshot.as_json
        }
      end

      # POST /api/v1/performance/generate_snapshot
      # Generate snapshot for current date
      def generate_snapshot
        snapshot = GeneratePerformanceSnapshotService.new(
          current_user,
          study_set: @study_set
        ).generate

        render json: {
          status: 'success',
          message: 'Snapshot generated successfully',
          data: snapshot.as_json
        }
      rescue StandardError => e
        render json: {
          status: 'error',
          message: e.message
        }, status: :internal_server_error
      end

      # GET /api/v1/performance/chart_data
      # Get data formatted for Chart.js
      def chart_data
        type = params[:chart_type] || 'trend'

        data = case type
        when 'trend'
          mastery_trend_chart_data
        when 'radar'
          subject_radar_chart_data
        when 'heatmap'
          time_heatmap_chart_data
        when 'progress'
          progress_chart_data
        else
          { error: 'Invalid chart type' }
        end

        render json: {
          status: 'success',
          data: data
        }
      end

      # GET /api/v1/performance/comparison
      # Compare performance with others
      def comparison
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        report = service.generate_report

        render json: {
          status: 'success',
          data: report[:comparative_analysis]
        }
      end

      private

      def set_study_set
        if params[:study_set_id]
          @study_set = StudySet.find(params[:study_set_id])

          unless @study_set.user_id == current_user.id
            render json: {
              status: 'error',
              message: 'Unauthorized'
            }, status: :unauthorized
          end
        end
      end

      def parse_date(date_string, default)
        return default unless date_string

        Date.parse(date_string)
      rescue ArgumentError
        default
      end

      # Chart data methods

      def mastery_trend_chart_data
        snapshots = PerformanceSnapshot
          .where(user_id: current_user.id)
          .where(study_set_id: params[:study_set_id])
          .where(period_type: 'daily')
          .where('snapshot_date >= ?', 30.days.ago)
          .order(snapshot_date: :asc)

        {
          labels: snapshots.map { |s| s.snapshot_date.strftime('%m/%d') },
          datasets: [
            {
              label: 'Mastery Level',
              data: snapshots.map(&:overall_mastery_level),
              borderColor: 'rgb(75, 192, 192)',
              backgroundColor: 'rgba(75, 192, 192, 0.2)',
              tension: 0.4
            },
            {
              label: 'Accuracy',
              data: snapshots.map { |s| s.overall_accuracy / 100.0 },
              borderColor: 'rgb(54, 162, 235)',
              backgroundColor: 'rgba(54, 162, 235, 0.2)',
              tension: 0.4
            }
          ]
        }
      end

      def subject_radar_chart_data
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        subjects = service.subject_breakdown

        {
          labels: subjects.map { |s| s[:subject_name] },
          datasets: [
            {
              label: 'Mastery Level',
              data: subjects.map { |s| s[:mastery_level] },
              backgroundColor: 'rgba(255, 99, 132, 0.2)',
              borderColor: 'rgb(255, 99, 132)',
              pointBackgroundColor: 'rgb(255, 99, 132)'
            }
          ]
        }
      end

      def time_heatmap_chart_data
        service = TimeBasedAnalysisService.new(current_user, study_set: @study_set)
        hourly = service.time_of_day_analysis[:hour_by_hour]

        # Group by day of week and hour
        days = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]

        data = days.map.with_index do |day, day_index|
          hourly.map do |hour_data|
            {
              x: hour_data[:hour_label],
              y: day,
              value: hour_data[:accuracy]
            }
          end
        end.flatten

        {
          data: data,
          xLabels: hourly.map { |h| h[:hour_label] },
          yLabels: days
        }
      end

      def progress_chart_data
        service = PerformanceReportService.new(current_user, study_set: @study_set)
        summary = service.quick_summary

        {
          labels: ['Mastered', 'Learning', 'Weak', 'Untested'],
          datasets: [
            {
              label: 'Concepts',
              data: [
                summary[:mastered],
                summary[:learning],
                summary[:weak],
                summary[:untested]
              ],
              backgroundColor: [
                'rgba(75, 192, 192, 0.8)',
                'rgba(255, 206, 86, 0.8)',
                'rgba(255, 99, 132, 0.8)',
                'rgba(201, 203, 207, 0.8)'
              ]
            }
          ]
        }
      end

      def authenticate_user!
        # Implement your authentication logic here
        # For now, assuming current_user is available
        unless current_user
          render json: {
            status: 'error',
            message: 'Authentication required'
          }, status: :unauthorized
        end
      end
    end
  end
end
