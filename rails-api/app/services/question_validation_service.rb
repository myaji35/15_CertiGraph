# Question Validation Service
class QuestionValidationService
  REQUIRED_FIELDS = %i[content options].freeze

  def validate_question_data(question_data)
    errors = []
    warnings = []

    # Required fields
    REQUIRED_FIELDS.each do |field|
      errors << "Missing required field: #{field}" if question_data[field].blank?
    end

    # Validate content
    if question_data[:content].present?
      content = question_data[:content].to_s
      errors << "Content too short" if content.length < 5
      warnings << "Content doesn't appear to be a question" unless content.include?('?') || content.include?('것은')
    end

    # Validate options
    if question_data[:options].present?
      options = question_data[:options]

      if options.is_a?(Hash)
        errors << "Insufficient options (need at least 2)" if options.size < 2
        options.each { |k, v| errors << "Option #{k} has blank value" if v.blank? }
      elsif options.is_a?(Array)
        errors << "Insufficient options" if options.size < 2
      else
        errors << "Options must be Hash or Array"
      end
    end

    # Validate answer
    if question_data[:answer].present? && question_data[:options].is_a?(Hash)
      answer = question_data[:answer]
      options = question_data[:options]
      unless options.key?(answer) || options.key?(answer.to_s)
        errors << "Answer '#{answer}' not found in options"
      end
    end

    {
      valid: errors.empty?,
      errors: errors,
      warnings: warnings
    }
  end

  def quick_validate(question_data)
    REQUIRED_FIELDS.all? { |field| question_data[field].present? }
  end
end
