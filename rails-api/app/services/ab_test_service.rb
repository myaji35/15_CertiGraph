class AbTestService
  # A/B Testing framework for weakness analysis and learning recommendations

  def initialize
  end

  # Create a new A/B test
  def create_test(params)
    ab_test = AbTest.create!(
      name: params[:name],
      description: params[:description],
      test_type: params[:test_type],
      variants: params[:variants] || default_variants,
      traffic_allocation: params[:traffic_allocation] || 1.0,
      primary_metrics: params[:primary_metrics] || ['accuracy_improvement'],
      secondary_metrics: params[:secondary_metrics] || ['engagement', 'completion_rate'],
      targeting_criteria: params[:targeting_criteria] || {},
      min_duration_days: params[:min_duration_days] || 7,
      max_duration_days: params[:max_duration_days] || 30,
      created_by: params[:created_by]
    )

    ab_test
  end

  # Assign user to test variant
  def assign_user_to_test(test_id, user)
    ab_test = AbTest.find(test_id)

    return nil unless ab_test.status == 'running'
    return nil unless should_include_user?(ab_test, user)

    assignment = ab_test.assign_user(user)
    assignment
  end

  # Get user's variant for a test
  def get_user_variant(test_id, user)
    assignment = AbTestAssignment.find_by(ab_test_id: test_id, user: user)
    assignment&.variant
  end

  # Track test event
  def track_event(test_id, user, event_type, event_data = {})
    assignment = AbTestAssignment.find_by(ab_test_id: test_id, user: user)
    return false unless assignment

    case event_type
    when 'interaction'
      assignment.record_interaction(event_data)
    when 'conversion'
      assignment.convert!(event_data)
    when 'metric'
      metric_name = event_data[:metric_name]
      metric_value = event_data[:metric_value]
      assignment.record_metric(metric_name, metric_value)
    end

    true
  end

  # Analyze test results
  def analyze_results(test_id)
    ab_test = AbTest.find(test_id)

    return { error: 'Test not running or completed' } unless %w[running completed].include?(ab_test.status)

    # Calculate statistical significance
    statistical_results = ab_test.calculate_statistical_significance

    # Get variant statistics
    variant_stats = ab_test.variant_statistics

    # Additional analysis
    {
      test_id: ab_test.id,
      test_name: ab_test.name,
      status: ab_test.status,
      duration_days: calculate_duration_days(ab_test),
      total_participants: ab_test.ab_test_assignments.count,
      variant_statistics: variant_stats,
      statistical_significance: statistical_results,
      winner: ab_test.winner_variant,
      recommendations: generate_recommendations(ab_test, statistical_results)
    }
  end

  # Check if test should be stopped
  def check_early_stopping(test_id)
    ab_test = AbTest.find(test_id)
    return false unless ab_test.status == 'running'

    # Check minimum duration
    duration = (Time.current - ab_test.started_at).to_i / 86400
    return false if duration < ab_test.min_duration_days

    # Check sample size
    total_participants = ab_test.ab_test_assignments.count
    return false if total_participants < (ab_test.sample_size_target || 100)

    # Check statistical significance
    results = ab_test.calculate_statistical_significance

    if results && results.values.any? { |r| r[:is_significant] && r[:p_value] < 0.01 }
      {
        should_stop: true,
        reason: 'Statistical significance achieved',
        winner: ab_test.winner_variant
      }
    else
      { should_stop: false }
    end
  end

  # Generate report
  def generate_report(test_id, format: 'json')
    ab_test = AbTest.find(test_id)
    analysis = analyze_results(test_id)

    case format
    when 'json'
      generate_json_report(ab_test, analysis)
    when 'pdf'
      generate_pdf_report(ab_test, analysis)
    else
      analysis
    end
  end

  # Common test configurations
  def self.recommendation_algorithm_test(created_by: nil)
    {
      name: 'Recommendation Algorithm Comparison',
      description: 'Test different recommendation algorithms (CF vs CB vs Hybrid)',
      test_type: 'algorithm',
      variants: {
        control: { algorithm: 'collaborative_filtering' },
        treatment_a: { algorithm: 'content_based' },
        treatment_b: { algorithm: 'hybrid' }
      },
      primary_metrics: ['accuracy_improvement', 'engagement'],
      secondary_metrics: ['completion_rate', 'time_on_task'],
      min_duration_days: 14,
      created_by: created_by
    }
  end

  def self.learning_path_strategy_test(created_by: nil)
    {
      name: 'Learning Path Strategy Test',
      description: 'Test different learning path generation strategies',
      test_type: 'learning_path',
      variants: {
        control: { strategy: 'shortest_path' },
        treatment_a: { strategy: 'difficulty_progression' },
        treatment_b: { strategy: 'mastery_based' }
      },
      primary_metrics: ['mastery_improvement', 'completion_rate'],
      secondary_metrics: ['study_time', 'satisfaction'],
      min_duration_days: 21,
      created_by: created_by
    }
  end

  def self.weakness_analysis_display_test(created_by: nil)
    {
      name: 'Weakness Analysis Display Format',
      description: 'Test different ways to present weakness analysis',
      test_type: 'ui',
      variants: {
        control: { display: 'list_view' },
        treatment_a: { display: 'heatmap_view' },
        treatment_b: { display: 'graph_view' }
      },
      primary_metrics: ['engagement', 'action_taken'],
      secondary_metrics: ['time_viewing', 'return_rate'],
      min_duration_days: 10,
      created_by: created_by
    }
  end

  private

  def default_variants
    {
      control: {},
      treatment: {}
    }
  end

  def should_include_user?(ab_test, user)
    # Check traffic allocation
    return false if rand > ab_test.traffic_allocation

    # Check targeting criteria
    criteria = ab_test.targeting_criteria

    return true if criteria.blank?

    # Check user segments
    if criteria['user_level']
      user_level = calculate_user_level(user)
      return false unless criteria['user_level'].include?(user_level)
    end

    if criteria['study_material_ids']
      user_material_ids = user.study_sets.includes(:study_materials)
                              .flat_map { |ss| ss.study_materials.pluck(:id) }
      return false if (criteria['study_material_ids'] & user_material_ids).empty?
    end

    if criteria['min_accuracy']
      user_accuracy = calculate_user_accuracy(user)
      return false if user_accuracy < criteria['min_accuracy']
    end

    true
  end

  def calculate_user_level(user)
    exam_answers_count = user.exam_answers.count

    case exam_answers_count
    when 0..50
      'beginner'
    when 51..200
      'intermediate'
    else
      'advanced'
    end
  end

  def calculate_user_accuracy(user)
    total = user.exam_answers.count
    return 0.0 if total.zero?

    correct = user.exam_answers.where(is_correct: true).count
    (correct.to_f / total * 100).round(2)
  end

  def calculate_duration_days(ab_test)
    return 0 unless ab_test.started_at

    end_time = ab_test.ended_at || Time.current
    ((end_time - ab_test.started_at).to_i / 86400).round
  end

  def generate_recommendations(ab_test, statistical_results)
    recommendations = []

    if ab_test.winner_variant
      recommendations << {
        type: 'winner_identified',
        message: "Variant '#{ab_test.winner_variant}' shows statistically significant improvement",
        action: 'Consider deploying this variant to all users'
      }
    elsif statistical_results && statistical_results.values.none? { |r| r[:is_significant] }
      recommendations << {
        type: 'no_winner',
        message: 'No statistically significant difference detected',
        action: 'Consider running test longer or trying different variants'
      }
    end

    # Sample size recommendations
    total_participants = ab_test.ab_test_assignments.count
    if total_participants < 100
      recommendations << {
        type: 'sample_size',
        message: 'Sample size is small',
        action: 'Increase test duration to gather more data'
      }
    end

    recommendations
  end

  def generate_json_report(ab_test, analysis)
    {
      report_type: 'ab_test_analysis',
      generated_at: Time.current,
      test: {
        id: ab_test.id,
        name: ab_test.name,
        type: ab_test.test_type,
        status: ab_test.status
      },
      analysis: analysis,
      metadata: {
        version: '1.0',
        format: 'json'
      }
    }
  end

  def generate_pdf_report(ab_test, analysis)
    # Placeholder for PDF generation
    # Would integrate with PDF generation service
    {
      report_type: 'pdf',
      url: "/reports/ab_test_#{ab_test.id}.pdf",
      message: 'PDF generation not yet implemented'
    }
  end
end
