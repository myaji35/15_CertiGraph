# app/services/randomization_analyzer.rb
class RandomizationAnalyzer
  SIGNIFICANCE_LEVEL = 0.05
  CRITICAL_CHI_SQUARE_4DF = 9.488 # 95% confidence, 4 degrees of freedom

  attr_reader :study_material, :questions, :stats

  def initialize(study_material)
    @study_material = study_material
    @questions = study_material.questions.includes(:options)
    @stats = []
  end

  # Analyze randomization quality for all questions
  def analyze_all_questions(iterations: 100)
    @stats = []

    @questions.each do |question|
      question_stats = analyze_question(question, iterations: iterations)
      @stats << question_stats
    end

    {
      study_material_id: @study_material.id,
      total_questions: @questions.count,
      analyzed_questions: @stats.count,
      overall_bias_score: calculate_overall_bias_score,
      biased_questions_count: count_biased_questions,
      uniformity_rate: calculate_uniformity_rate,
      quality_rating: overall_quality_rating,
      question_stats: @stats,
      analyzed_at: Time.current
    }
  end

  # Analyze a single question's randomization
  def analyze_question(question, iterations: 100)
    options = extract_options(question)
    return empty_analysis(question) if options.empty?

    randomizer = AnswerRandomizer.new(strategy: 'full_random')
    position_counts = initialize_position_counts(options)

    # Run randomization multiple times
    iterations.times do
      result = randomizer.randomize_question_options(question)
      record_positions(result[:randomized_options], position_counts)
    end

    # Calculate statistics for each option
    option_stats = calculate_option_statistics(question, options, position_counts, iterations)

    # Calculate overall question statistics
    overall_chi_square = calculate_overall_chi_square(option_stats)
    overall_p_value = chi_square_to_p_value(overall_chi_square, options.size - 1)
    overall_bias_score = calculate_bias_score(option_stats)

    {
      question_id: question.id,
      question_number: question.question_number,
      options_count: options.size,
      iterations: iterations,
      option_stats: option_stats,
      overall_chi_square: overall_chi_square.round(4),
      overall_p_value: overall_p_value.round(4),
      overall_bias_score: overall_bias_score.round(2),
      is_uniform: overall_p_value >= SIGNIFICANCE_LEVEL && overall_bias_score < 20.0,
      quality_rating: quality_rating_from_bias(overall_bias_score)
    }
  end

  # Perform chi-square test for uniformity
  def chi_square_test(observed_frequencies)
    return { statistic: 0.0, p_value: 1.0, is_uniform: true } if observed_frequencies.empty?

    total = observed_frequencies.sum
    return { statistic: 0.0, p_value: 1.0, is_uniform: true } if total.zero?

    expected = total.to_f / observed_frequencies.size
    chi_square = observed_frequencies.sum { |observed| ((observed - expected)**2) / expected }

    degrees_of_freedom = observed_frequencies.size - 1
    p_value = chi_square_to_p_value(chi_square, degrees_of_freedom)

    {
      statistic: chi_square.round(4),
      p_value: p_value.round(4),
      degrees_of_freedom: degrees_of_freedom,
      is_uniform: p_value >= SIGNIFICANCE_LEVEL
    }
  end

  # Calculate bias score (0-100, lower is better)
  def calculate_bias_score_for_distribution(position_counts)
    return 0.0 if position_counts.empty?

    total = position_counts.sum
    return 0.0 if total.zero?

    expected = total.to_f / position_counts.size
    max_deviation = position_counts.map { |count| (count - expected).abs }.max

    # Normalize to 0-100 scale
    (max_deviation / expected * 100).round(2)
  end

  # Save analysis results to database
  def save_analysis_results(analysis_results)
    analysis_results[:question_stats].each do |question_stat|
      question_stat[:option_stats].each do |option_stat|
        save_option_stat(question_stat, option_stat)
      end
    end
  end

  # Generate detailed report
  def generate_report
    analysis = analyze_all_questions(iterations: 100)

    {
      summary: {
        study_material: @study_material.title,
        total_questions: analysis[:total_questions],
        overall_bias_score: analysis[:overall_bias_score],
        uniformity_rate: "#{(analysis[:uniformity_rate] * 100).round(1)}%",
        quality_rating: analysis[:quality_rating]
      },
      biased_questions: find_biased_questions(analysis),
      recommendations: generate_recommendations(analysis),
      detailed_stats: analysis[:question_stats]
    }
  end

  private

  def extract_options(question)
    if question.respond_to?(:options) && question.options.is_a?(Hash)
      question.options.map.with_index do |(key, content), index|
        { id: index, label: key, content: content, is_correct: (key == question.answer) }
      end
    elsif question.respond_to?(:options) && question.options.respond_to?(:map)
      question.options.ordered.map do |option|
        { id: option.id, label: option.label, content: option.content, is_correct: option.is_correct }
      end
    else
      []
    end
  end

  def initialize_position_counts(options)
    Hash.new do |h, option_id|
      h[option_id] = Array.new(options.size, 0)
    end
  end

  def record_positions(randomized_options, position_counts)
    randomized_options.each_with_index do |option, position|
      position_counts[option[:id]][position] += 1
    end
  end

  def calculate_option_statistics(question, options, position_counts, iterations)
    options.map do |option|
      counts = position_counts[option[:id]]
      chi_square_result = chi_square_test(counts)

      {
        option_id: option[:id],
        option_label: option[:label],
        is_correct: option[:is_correct],
        position_counts: counts,
        total_appearances: counts.sum,
        chi_square: chi_square_result[:statistic],
        p_value: chi_square_result[:p_value],
        bias_score: calculate_bias_score_for_distribution(counts),
        is_uniform: chi_square_result[:is_uniform],
        distribution_summary: distribution_summary(counts, iterations)
      }
    end
  end

  def calculate_overall_chi_square(option_stats)
    option_stats.sum { |stat| stat[:chi_square] }
  end

  def calculate_bias_score(option_stats)
    return 0.0 if option_stats.empty?

    # Average bias score across all options
    total_bias = option_stats.sum { |stat| stat[:bias_score] }
    (total_bias / option_stats.size).round(2)
  end

  def calculate_overall_bias_score
    return 0.0 if @stats.empty?

    total_bias = @stats.sum { |stat| stat[:overall_bias_score] }
    (total_bias / @stats.size).round(2)
  end

  def count_biased_questions
    @stats.count { |stat| !stat[:is_uniform] }
  end

  def calculate_uniformity_rate
    return 0.0 if @stats.empty?
    uniform_count = @stats.count { |stat| stat[:is_uniform] }
    uniform_count.to_f / @stats.size
  end

  def overall_quality_rating
    bias_score = calculate_overall_bias_score
    quality_rating_from_bias(bias_score)
  end

  def quality_rating_from_bias(bias_score)
    case bias_score
    when 0..5 then 'excellent'
    when 5..10 then 'good'
    when 10..20 then 'acceptable'
    when 20..30 then 'poor'
    else 'very_poor'
    end
  end

  def find_biased_questions(analysis)
    analysis[:question_stats].select { |stat| !stat[:is_uniform] }
  end

  def generate_recommendations(analysis)
    recommendations = []

    if analysis[:overall_bias_score] > 20
      recommendations << "Consider using 'constrained_random' strategy to reduce bias"
    end

    if analysis[:uniformity_rate] < 0.8
      recommendations << "#{((1 - analysis[:uniformity_rate]) * 100).round(1)}% of questions show non-uniform distribution"
    end

    biased = find_biased_questions(analysis)
    if biased.any?
      recommendations << "Review #{biased.size} questions with significant bias"
    end

    recommendations << "Overall quality: #{analysis[:quality_rating]}"

    recommendations
  end

  def distribution_summary(counts, total)
    return "No data" if total.zero?

    percentages = counts.map { |c| ((c.to_f / total) * 100).round(1) }
    "Positions: " + percentages.map.with_index { |p, i| "#{i + 1}: #{p}%" }.join(', ')
  end

  def chi_square_to_p_value(chi_square, degrees_of_freedom)
    # Simplified p-value estimation using chi-square distribution
    # For accurate results, use a statistics library like 'statistics2'
    # This is a rough approximation

    return 1.0 if chi_square.zero?

    # Using critical values for common degrees of freedom
    critical_values = {
      1 => 3.841,
      2 => 5.991,
      3 => 7.815,
      4 => 9.488,
      5 => 11.070
    }

    critical = critical_values[degrees_of_freedom] || 9.488

    # Rough approximation: if chi_square < critical, p > 0.05
    if chi_square < critical
      0.5 # Approximate p-value > 0.05
    elsif chi_square < critical * 2
      0.02 # Approximate p-value ~ 0.01-0.05
    else
      0.001 # Approximate p-value < 0.01
    end
  end

  def empty_analysis(question)
    {
      question_id: question.id,
      question_number: question.question_number,
      options_count: 0,
      iterations: 0,
      option_stats: [],
      overall_chi_square: 0.0,
      overall_p_value: 1.0,
      overall_bias_score: 0.0,
      is_uniform: true,
      quality_rating: 'no_data'
    }
  end

  def save_option_stat(question_stat, option_stat)
    RandomizationStat.find_or_initialize_by(
      study_material_id: @study_material.id,
      question_id: question_stat[:question_id],
      option_id: option_stat[:option_id]
    ).tap do |stat|
      stat.option_label = option_stat[:option_label]
      stat.position_0_count = option_stat[:position_counts][0] || 0
      stat.position_1_count = option_stat[:position_counts][1] || 0
      stat.position_2_count = option_stat[:position_counts][2] || 0
      stat.position_3_count = option_stat[:position_counts][3] || 0
      stat.position_4_count = option_stat[:position_counts][4] || 0
      stat.total_randomizations = option_stat[:total_appearances]
      stat.chi_square_statistic = option_stat[:chi_square]
      stat.p_value = option_stat[:p_value]
      stat.bias_score = option_stat[:bias_score]
      stat.is_uniform = option_stat[:is_uniform]
      stat.position_distribution = option_stat[:position_counts].each_with_index.to_h
      stat.last_analyzed_at = Time.current
      stat.save!
    end
  end
end
