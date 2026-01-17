class AbTestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ab_test, only: [:show, :update, :destroy, :start, :pause, :complete, :results, :assign_variant]
  before_action :require_admin, only: [:create, :update, :destroy, :start, :pause, :complete]

  # GET /ab_tests
  def index
    @ab_tests = AbTest.all.order(created_at: :desc)

    if params[:status]
      @ab_tests = @ab_tests.where(status: params[:status])
    end

    render json: {
      success: true,
      ab_tests: @ab_tests.map { |test| format_ab_test(test) }
    }
  end

  # GET /ab_tests/:id
  def show
    render json: {
      success: true,
      ab_test: format_ab_test_detailed(@ab_test)
    }
  end

  # POST /ab_tests
  def create
    ab_test_service = AbTestService.new

    @ab_test = ab_test_service.create_test(test_params.merge(created_by: current_user))

    render json: {
      success: true,
      ab_test: format_ab_test(@ab_test),
      message: 'A/B test created successfully'
    }, status: :created
  rescue StandardError => e
    render json: {
      success: false,
      message: "Failed to create A/B test: #{e.message}"
    }, status: :unprocessable_entity
  end

  # PATCH /ab_tests/:id
  def update
    if @ab_test.update(test_params)
      render json: {
        success: true,
        ab_test: format_ab_test(@ab_test),
        message: 'A/B test updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @ab_test.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /ab_tests/:id
  def destroy
    @ab_test.destroy

    render json: {
      success: true,
      message: 'A/B test deleted successfully'
    }
  end

  # POST /ab_tests/:id/start
  def start
    if @ab_test.start!
      render json: {
        success: true,
        ab_test: format_ab_test(@ab_test),
        message: 'A/B test started'
      }
    else
      render json: {
        success: false,
        message: 'Cannot start test. Check test status.'
      }, status: :unprocessable_entity
    end
  end

  # POST /ab_tests/:id/pause
  def pause
    if @ab_test.pause!
      render json: {
        success: true,
        ab_test: format_ab_test(@ab_test),
        message: 'A/B test paused'
      }
    else
      render json: {
        success: false,
        message: 'Cannot pause test'
      }, status: :unprocessable_entity
    end
  end

  # POST /ab_tests/:id/complete
  def complete
    if @ab_test.complete!
      # Run final analysis
      ab_test_service = AbTestService.new
      analysis = ab_test_service.analyze_results(@ab_test.id)

      render json: {
        success: true,
        ab_test: format_ab_test(@ab_test),
        final_analysis: analysis,
        message: 'A/B test completed'
      }
    else
      render json: {
        success: false,
        message: 'Cannot complete test'
      }, status: :unprocessable_entity
    end
  end

  # GET /ab_tests/:id/results
  def results
    ab_test_service = AbTestService.new
    analysis = ab_test_service.analyze_results(@ab_test.id)

    render json: {
      success: true,
      results: analysis
    }
  end

  # POST /ab_tests/:id/assign_variant
  def assign_variant
    ab_test_service = AbTestService.new
    assignment = ab_test_service.assign_user_to_test(@ab_test.id, current_user)

    if assignment
      render json: {
        success: true,
        assignment: {
          variant: assignment.variant,
          assigned_at: assignment.assigned_at
        }
      }
    else
      render json: {
        success: false,
        message: 'Cannot assign variant. Test may not be running or user not eligible.'
      }, status: :unprocessable_entity
    end
  end

  # POST /ab_tests/:id/track_event
  def track_event
    ab_test_service = AbTestService.new

    event_type = params[:event_type]
    event_data = params[:event_data] || {}

    success = ab_test_service.track_event(@ab_test.id, current_user, event_type, event_data)

    if success
      render json: {
        success: true,
        message: 'Event tracked successfully'
      }
    else
      render json: {
        success: false,
        message: 'Failed to track event'
      }, status: :unprocessable_entity
    end
  end

  # GET /ab_tests/:id/early_stopping_check
  def early_stopping_check
    ab_test_service = AbTestService.new
    check_result = ab_test_service.check_early_stopping(@ab_test.id)

    render json: {
      success: true,
      early_stopping: check_result
    }
  end

  # GET /ab_tests/:id/report
  def report
    ab_test_service = AbTestService.new
    format = params[:format] || 'json'

    report = ab_test_service.generate_report(@ab_test.id, format: format)

    render json: {
      success: true,
      report: report
    }
  end

  # GET /ab_tests/templates
  def templates
    render json: {
      success: true,
      templates: [
        AbTestService.recommendation_algorithm_test,
        AbTestService.learning_path_strategy_test,
        AbTestService.weakness_analysis_display_test
      ]
    }
  end

  private

  def set_ab_test
    @ab_test = AbTest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'A/B test not found'
    }, status: :not_found
  end

  def test_params
    params.require(:ab_test).permit(
      :name,
      :description,
      :test_type,
      :traffic_allocation,
      :sample_size_target,
      :min_duration_days,
      :max_duration_days,
      variants: {},
      primary_metrics: [],
      secondary_metrics: [],
      targeting_criteria: {}
    )
  end

  def require_admin
    unless current_user.role == 'admin'
      render json: {
        success: false,
        message: 'Admin access required'
      }, status: :forbidden
    end
  end

  def format_ab_test(test)
    {
      id: test.id,
      name: test.name,
      test_type: test.test_type,
      status: test.status,
      started_at: test.started_at,
      ended_at: test.ended_at,
      participants_count: test.ab_test_assignments.count,
      winner: test.winner_variant,
      is_significant: test.is_significant
    }
  end

  def format_ab_test_detailed(test)
    format_ab_test(test).merge(
      description: test.description,
      variants: test.variants,
      traffic_allocation: test.traffic_allocation,
      primary_metrics: test.primary_metrics,
      secondary_metrics: test.secondary_metrics,
      results: test.results,
      confidence_level: test.confidence_level,
      p_value: test.p_value,
      variant_statistics: test.variant_statistics
    )
  end
end
