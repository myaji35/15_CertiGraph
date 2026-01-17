# app/controllers/randomization_controller.rb
class RandomizationController < ApplicationController
  before_action :authenticate_user!
  before_action :set_study_material, only: [:analyze, :report, :stats, :question_stats]
  before_action :set_exam_session, only: [:session_randomization, :restore_order]

  # POST /api/randomization/randomize
  # Randomize options for a single question
  def randomize_question
    question = Question.find(params[:question_id])

    strategy = params[:strategy] || 'full_random'
    seed = params[:seed] || params[:use_existing_seed]

    randomizer = AnswerRandomizer.new(strategy: strategy, seed: seed)
    result = randomizer.randomize_question_options(question)

    render json: {
      success: true,
      question_id: question.id,
      randomization: result,
      seed: randomizer.seed
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Question not found' }, status: :not_found
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # POST /api/randomization/randomize_exam
  # Randomize all questions in an exam session
  def randomize_exam
    exam_session = ExamSession.find(params[:exam_session_id])

    unless exam_session.user_id == current_user.id
      return render json: { success: false, error: 'Unauthorized' }, status: :forbidden
    end

    questions = exam_session.study_set.study_material.questions
    strategy = params[:strategy] || exam_session.randomization_strategy || 'full_random'
    seed = exam_session.randomization_seed || AnswerRandomizer.generate_seed

    randomizer = AnswerRandomizer.new(strategy: strategy, seed: seed)
    results = randomizer.randomize_exam_questions(questions)

    # Update exam session with seed
    exam_session.update!(
      randomization_seed: seed,
      randomization_strategy: strategy,
      randomization_enabled: true
    )

    render json: {
      success: true,
      exam_session_id: exam_session.id,
      seed: seed,
      strategy: strategy,
      randomizations: results
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Exam session not found' }, status: :not_found
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/randomization/session/:id
  # Get randomization info for an exam session
  def session_randomization
    render json: {
      success: true,
      exam_session_id: @exam_session.id,
      randomization_enabled: @exam_session.randomization_enabled,
      randomization_seed: @exam_session.randomization_seed,
      randomization_strategy: @exam_session.randomization_strategy,
      can_restore: @exam_session.randomization_seed.present?
    }
  end

  # POST /api/randomization/restore
  # Restore original order using seed
  def restore_order
    question = Question.find(params[:question_id])
    randomized_options = params[:randomized_options]

    unless @exam_session.randomization_seed.present?
      return render json: { success: false, error: 'No seed available' }, status: :unprocessable_entity
    end

    randomizer = AnswerRandomizer.from_seed(
      @exam_session.randomization_seed,
      strategy: @exam_session.randomization_strategy
    )

    # Get original randomization
    original_result = randomizer.randomize_question_options(question)
    restored = randomizer.restore_original_order(
      randomized_options,
      original_result[:option_map]
    )

    render json: {
      success: true,
      question_id: question.id,
      restored_options: restored
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # POST /api/randomization/analyze
  # Analyze randomization quality for a study material
  def analyze
    iterations = params[:iterations]&.to_i || 100

    analyzer = RandomizationAnalyzer.new(@study_material)
    analysis = analyzer.analyze_all_questions(iterations: iterations)

    # Save results if requested
    if params[:save_results]
      analyzer.save_analysis_results(analysis)
    end

    render json: {
      success: true,
      analysis: analysis
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/randomization/report/:study_material_id
  # Generate detailed randomization quality report
  def report
    analyzer = RandomizationAnalyzer.new(@study_material)
    report = analyzer.generate_report

    render json: {
      success: true,
      report: report
    }
  rescue => e
    render json: { success: false, error: e.message }, status: :unprocessable_entity
  end

  # GET /api/randomization/stats/:study_material_id
  # Get saved randomization statistics
  def stats
    stats = RandomizationStat.by_material(@study_material.id)
                             .includes(:question)
                             .order('bias_score DESC')

    summary = {
      total_stats: stats.count,
      average_bias_score: stats.average(:bias_score)&.round(2) || 0.0,
      uniform_count: stats.uniform.count,
      non_uniform_count: stats.non_uniform.count,
      biased_count: stats.biased.count
    }

    render json: {
      success: true,
      summary: summary,
      stats: stats.map { |stat| format_stat(stat) }
    }
  end

  # GET /api/randomization/question_stats/:study_material_id/:question_id
  # Get detailed stats for a specific question
  def question_stats
    question = @study_material.questions.find(params[:question_id])
    stats = RandomizationStat.by_material(@study_material.id)
                             .by_question(question.id)

    render json: {
      success: true,
      question_id: question.id,
      question_number: question.question_number,
      stats: stats.map { |stat| format_detailed_stat(stat) }
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Question not found' }, status: :not_found
  end

  # POST /api/randomization/test_uniformity
  # Test uniformity of randomization algorithm
  def test_uniformity
    iterations = params[:iterations]&.to_i || 1000
    num_options = params[:num_options]&.to_i || 5
    strategy = params[:strategy] || 'full_random'

    randomizer = AnswerRandomizer.new(strategy: strategy)
    position_counts = randomizer.test_uniformity(
      iterations: iterations,
      num_options: num_options
    )

    # Calculate statistics
    analyzer = RandomizationAnalyzer.new(nil)
    uniformity_tests = position_counts.map.with_index do |position_hash, position|
      counts = position_hash.values
      test_result = analyzer.chi_square_test(counts)

      {
        position: position,
        counts: position_hash,
        chi_square: test_result[:statistic],
        p_value: test_result[:p_value],
        is_uniform: test_result[:is_uniform]
      }
    end

    render json: {
      success: true,
      test_config: {
        iterations: iterations,
        num_options: num_options,
        strategy: strategy
      },
      position_counts: position_counts,
      uniformity_tests: uniformity_tests,
      overall_uniformity: uniformity_tests.all? { |test| test[:is_uniform] }
    }
  end

  # PUT /api/randomization/toggle/:exam_session_id
  # Toggle randomization on/off for exam session
  def toggle_randomization
    exam_session = ExamSession.find(params[:exam_session_id])

    unless exam_session.user_id == current_user.id
      return render json: { success: false, error: 'Unauthorized' }, status: :forbidden
    end

    exam_session.update!(
      randomization_enabled: !exam_session.randomization_enabled
    )

    render json: {
      success: true,
      exam_session_id: exam_session.id,
      randomization_enabled: exam_session.randomization_enabled
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Exam session not found' }, status: :not_found
  end

  # PUT /api/randomization/set_strategy/:exam_session_id
  # Set randomization strategy for exam session
  def set_strategy
    exam_session = ExamSession.find(params[:exam_session_id])

    unless exam_session.user_id == current_user.id
      return render json: { success: false, error: 'Unauthorized' }, status: :forbidden
    end

    strategy = params[:strategy]
    unless AnswerRandomizer::STRATEGIES.include?(strategy)
      return render json: {
        success: false,
        error: "Invalid strategy. Must be one of: #{AnswerRandomizer::STRATEGIES.join(', ')}"
      }, status: :unprocessable_entity
    end

    exam_session.update!(randomization_strategy: strategy)

    render json: {
      success: true,
      exam_session_id: exam_session.id,
      randomization_strategy: exam_session.randomization_strategy
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Exam session not found' }, status: :not_found
  end

  # POST /api/randomization/analyze_job/:study_material_id
  # Queue background job for analysis
  def analyze_job
    study_material = StudyMaterial.find(params[:study_material_id])

    unless study_material.user_id == current_user.id || current_user.admin?
      return render json: { success: false, error: 'Unauthorized' }, status: :forbidden
    end

    iterations = params[:iterations]&.to_i || 100
    job = AnalyzeRandomizationJob.perform_later(study_material.id, iterations)

    render json: {
      success: true,
      message: 'Analysis job queued',
      study_material_id: study_material.id,
      job_id: job.job_id
    }
  rescue ActiveRecord::RecordNotFound => e
    render json: { success: false, error: 'Study material not found' }, status: :not_found
  end

  private

  def set_study_material
    @study_material = StudyMaterial.find(params[:study_material_id])
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Study material not found' }, status: :not_found
  end

  def set_exam_session
    @exam_session = ExamSession.find(params[:id] || params[:exam_session_id])

    unless @exam_session.user_id == current_user.id
      render json: { success: false, error: 'Unauthorized' }, status: :forbidden
    end
  rescue ActiveRecord::RecordNotFound
    render json: { success: false, error: 'Exam session not found' }, status: :not_found
  end

  def format_stat(stat)
    {
      id: stat.id,
      question_id: stat.question_id,
      question_number: stat.question&.question_number,
      option_label: stat.option_label,
      total_randomizations: stat.total_randomizations,
      bias_score: stat.bias_score,
      quality_rating: stat.quality_rating,
      is_uniform: stat.is_uniform,
      distribution_summary: stat.distribution_summary
    }
  end

  def format_detailed_stat(stat)
    {
      id: stat.id,
      option_id: stat.option_id,
      option_label: stat.option_label,
      position_counts: stat.position_counts,
      total_randomizations: stat.total_randomizations,
      chi_square: stat.chi_square_statistic,
      p_value: stat.p_value,
      bias_score: stat.bias_score,
      is_uniform: stat.is_uniform,
      quality_rating: stat.quality_rating,
      distribution_summary: stat.distribution_summary,
      most_frequent_position: stat.most_frequent_position,
      least_frequent_position: stat.least_frequent_position,
      coefficient_of_variation: stat.coefficient_of_variation.round(2),
      last_analyzed_at: stat.last_analyzed_at
    }
  end
end
