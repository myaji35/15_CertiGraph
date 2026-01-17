# Question Validation Service
# Validates extracted questions for quality and completeness
class QuestionValidationService
  # Quality thresholds
  MIN_QUESTION_LENGTH = 10
  MIN_OPTION_LENGTH = 1
  MIN_OPTIONS_COUNT = 2
  MAX_OPTIONS_COUNT = 5
  MIN_CONFIDENCE_SCORE = 0.5

  # Validate a single question data hash
  # @param question_data [Hash] Question data to validate
  # @return [Hash] { valid: Boolean, errors: Array, warnings: Array, score: Float }
  def validate_question_data(question_data)
    errors = []
    warnings = []
    score = 100.0

    # Required field validations
    errors << "Missing question content" if question_data[:content].blank?
    errors << "Missing question number" if question_data[:question_number].nil?

    # Content length validation
    if question_data[:content].present? && question_data[:content].length < MIN_QUESTION_LENGTH
      errors << "Question content too short (minimum #{MIN_QUESTION_LENGTH} characters)"
      score -= 20
    end

    # Question type validation
    question_type = question_data[:question_type] || 'multiple_choice'
    unless Question::QUESTION_TYPES.include?(question_type)
      errors << "Invalid question type: #{question_type}"
      score -= 15
    end

    # Options validation for multiple choice
    if question_type == 'multiple_choice'
      options_errors = validate_options(question_data[:options])
      errors.concat(options_errors)
      score -= (options_errors.size * 10)
    end

    # Answer validation
    if question_data[:answer].blank? && question_type != 'short_answer'
      errors << "Missing correct answer"
      score -= 30
    elsif question_data[:answer].present? && question_type == 'multiple_choice'
      unless question_data[:options]&.key?(question_data[:answer])
        errors << "Answer '#{question_data[:answer]}' not found in options"
        score -= 25
      end
    end

    # Difficulty validation
    difficulty = question_data[:difficulty]
    if difficulty && (difficulty < 1 || difficulty > 5)
      warnings << "Difficulty should be between 1 and 5, got #{difficulty}"
      score -= 5
    end

    # Confidence score validation
    confidence = question_data[:confidence_score] || 0.0
    if confidence < MIN_CONFIDENCE_SCORE
      warnings << "Low confidence score: #{confidence.round(2)}"
      score -= 10
    end

    # Explanation validation
    if question_data[:explanation].blank?
      warnings << "Missing explanation"
      score -= 5
    end

    # Duplicate detection
    if detect_duplicate_options(question_data[:options])
      warnings << "Possible duplicate options detected"
      score -= 10
    end

    score = [score, 0].max # Ensure score doesn't go negative

    {
      valid: errors.empty?,
      errors: errors,
      warnings: warnings,
      score: score,
      quality_level: quality_level(score)
    }
  end

  # Validate a Question model instance
  # @param question [Question] Question to validate
  # @return [Hash] Validation result
  def validate_question_model(question)
    question_data = {
      content: question.content,
      question_number: question.question_number,
      question_type: question.question_type,
      options: question.options,
      answer: question.answer,
      explanation: question.explanation,
      difficulty: question.difficulty,
      confidence_score: question.ai_confidence_score
    }

    validate_question_data(question_data)
  end

  # Batch validate multiple questions
  # @param questions_data [Array<Hash>] Array of question data
  # @return [Hash] { valid_count: Integer, invalid_count: Integer, results: Array }
  def batch_validate(questions_data)
    results = questions_data.map { |q| validate_question_data(q) }

    {
      valid_count: results.count { |r| r[:valid] },
      invalid_count: results.count { |r| !r[:valid] },
      avg_score: results.sum { |r| r[:score] } / [results.size, 1].max,
      results: results,
      quality_distribution: results.group_by { |r| r[:quality_level] }.transform_values(&:count)
    }
  end

  # Detect potential issues in extracted questions
  # @param questions [Array<Question>] Questions to analyze
  # @return [Hash] Issues found
  def detect_issues(questions)
    issues = {
      duplicates: [],
      missing_explanations: [],
      low_quality: [],
      inconsistent_numbering: []
    }

    # Check for duplicate questions
    content_map = Hash.new { |h, k| h[k] = [] }
    questions.each do |q|
      content_map[q.content.strip.downcase] << q.id
    end

    content_map.each do |content, ids|
      issues[:duplicates] << { content: content.truncate(100), question_ids: ids } if ids.size > 1
    end

    # Check for missing explanations
    issues[:missing_explanations] = questions.select { |q| q.explanation.blank? }.map(&:id)

    # Check for low quality
    questions.each do |q|
      result = validate_question_model(q)
      issues[:low_quality] << { id: q.id, score: result[:score] } if result[:score] < 50
    end

    # Check for inconsistent numbering
    numbers = questions.map(&:question_number).compact.sort
    expected = (1..numbers.last).to_a if numbers.any?
    missing = expected - numbers if expected
    issues[:inconsistent_numbering] = missing if missing&.any?

    issues
  end

  private

  def validate_options(options)
    errors = []

    if options.blank?
      errors << "Missing options"
      return errors
    end

    unless options.is_a?(Hash)
      errors << "Options must be a hash"
      return errors
    end

    # Check option count
    if options.size < MIN_OPTIONS_COUNT
      errors << "Too few options (minimum #{MIN_OPTIONS_COUNT})"
    elsif options.size > MAX_OPTIONS_COUNT
      errors << "Too many options (maximum #{MAX_OPTIONS_COUNT})"
    end

    # Check each option
    options.each do |key, value|
      if value.blank?
        errors << "Empty option for key '#{key}'"
      elsif value.length < MIN_OPTION_LENGTH
        errors << "Option '#{key}' is too short"
      end
    end

    errors
  end

  def detect_duplicate_options(options)
    return false if options.blank?

    values = options.values.map { |v| v.to_s.strip.downcase }
    values.size != values.uniq.size
  end

  def quality_level(score)
    case score
    when 90..100 then 'excellent'
    when 70..89 then 'good'
    when 50..69 then 'fair'
    when 30..49 then 'poor'
    else 'very_poor'
    end
  end
end
