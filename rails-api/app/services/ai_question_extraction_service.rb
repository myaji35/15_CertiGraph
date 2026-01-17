# AI-powered Question Extraction Service
# Uses GPT-4o to intelligently extract questions, options, answers, and explanations from markdown content
class AiQuestionExtractionService
  attr_reader :markdown_content, :study_material, :openai_client

  def initialize(markdown_content, study_material: nil)
    @markdown_content = markdown_content
    @study_material = study_material
    @openai_client = OpenaiClient.new
  end

  # Extract all questions using AI
  # @return [Hash] { questions: Array, passages: Array, stats: Hash }
  def extract
    return { questions: [], passages: [], stats: {}, error: "Content is blank" } if @markdown_content.blank?

    begin
      # Step 1: Detect and extract passages
      passage_service = PassageDetectionService.new(@markdown_content)
      passages_data = passage_service.detect_passages

      # Step 2: Extract questions using GPT-4o
      questions_data = extract_questions_with_ai(passages_data)

      # Step 3: Match questions with passages
      matched_data = match_questions_to_passages(questions_data, passages_data)

      # Step 4: Validate extracted questions
      validated_data = validate_extracted_questions(matched_data)

      {
        questions: validated_data[:questions],
        passages: validated_data[:passages],
        stats: generate_extraction_stats(validated_data),
        success: true
      }
    rescue StandardError => e
      Rails.logger.error("AI Question Extraction Error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      { questions: [], passages: [], stats: {}, error: e.message, success: false }
    end
  end

  # Save extracted data to database
  # @param extracted_data [Hash] Result from extract method
  # @return [Hash] { questions_created: Integer, passages_created: Integer, errors: Array }
  def save_to_database(extracted_data)
    return { error: "No study material provided" } unless @study_material

    ActiveRecord::Base.transaction do
      results = {
        questions_created: 0,
        passages_created: 0,
        errors: []
      }

      # Create passages
      passage_map = {}
      extracted_data[:passages].each do |passage_data|
        passage = @study_material.passages.create!(
          content: passage_data[:content],
          passage_type: passage_data[:type] || 'text',
          position: passage_data[:position],
          has_image: passage_data[:has_image] || false,
          has_table: passage_data[:has_table] || false,
          character_count: passage_data[:content].length,
          metadata: passage_data[:metadata] || {}
        )
        passage_map[passage_data[:id]] = passage
        results[:passages_created] += 1
      end

      # Create questions
      extracted_data[:questions].each do |question_data|
        begin
          question = @study_material.questions.create!(
            question_number: question_data[:question_number],
            content: question_data[:content],
            options: question_data[:options],
            answer: question_data[:answer],
            explanation: question_data[:explanation],
            question_type: question_data[:question_type] || 'multiple_choice',
            difficulty: question_data[:difficulty],
            has_image: question_data[:has_image] || false,
            has_table: question_data[:has_table] || false,
            ai_confidence_score: question_data[:confidence_score] || 0.0,
            extraction_metadata: question_data[:metadata] || {}
          )

          # Link to passages
          if question_data[:passage_ids].present?
            question_data[:passage_ids].each do |passage_id|
              passage = passage_map[passage_id]
              next unless passage

              question.add_passage(
                passage,
                is_primary: question_data[:primary_passage_id] == passage_id,
                relevance_score: 100
              )
            end
          end

          # Validate the question
          question.validate_question!
          results[:questions_created] += 1
        rescue StandardError => e
          results[:errors] << { question_number: question_data[:question_number], error: e.message }
        end
      end

      results
    end
  rescue StandardError => e
    Rails.logger.error("Database save error: #{e.message}")
    { error: e.message, questions_created: 0, passages_created: 0, errors: [] }
  end

  private

  def extract_questions_with_ai(passages_data)
    prompt = build_extraction_prompt(passages_data)

    response = @openai_client.reason_with_gpt4o(
      prompt,
      context: "You are extracting questions from exam materials. Be precise and thorough.",
      temperature: 0.3
    )

    parse_ai_response(response)
  rescue StandardError => e
    Rails.logger.error("AI extraction failed: #{e.message}")
    fallback_to_regex_extraction
  end

  def build_extraction_prompt(passages_data)
    <<~PROMPT
      Extract all questions from the following markdown content. For each question, identify:
      1. Question number
      2. Question text
      3. All answer options (①, ②, ③, ④, ⑤)
      4. Correct answer
      5. Explanation (if present)
      6. Associated passage ID (if question refers to a passage)
      7. Question type (multiple_choice, true_false, short_answer)
      8. Difficulty level (1-5)

      Passages detected:
      #{format_passages_for_prompt(passages_data)}

      Content to analyze:
      #{@markdown_content.truncate(6000)}

      Return a JSON array with this structure:
      [
        {
          "question_number": 1,
          "content": "question text",
          "options": {"①": "option 1", "②": "option 2", "③": "option 3", "④": "option 4"},
          "answer": "①",
          "explanation": "explanation text",
          "passage_ids": [1, 2],
          "primary_passage_id": 1,
          "question_type": "multiple_choice",
          "difficulty": 3,
          "has_image": false,
          "has_table": false,
          "confidence_score": 0.95
        }
      ]

      IMPORTANT: Return ONLY valid JSON. No markdown, no code blocks, just JSON.
    PROMPT
  end

  def format_passages_for_prompt(passages_data)
    return "No passages detected." if passages_data[:passages].blank?

    passages_data[:passages].map do |p|
      "Passage #{p[:id]} (position #{p[:position]}): #{p[:content].truncate(200)}"
    end.join("\n")
  end

  def parse_ai_response(response)
    # Remove markdown code blocks if present
    cleaned_response = response.gsub(/```json\n?/, '').gsub(/```\n?/, '').strip

    JSON.parse(cleaned_response)
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse AI response as JSON: #{e.message}")
    Rails.logger.error("Response was: #{response}")
    fallback_to_regex_extraction
  end

  def fallback_to_regex_extraction
    # Fallback to the existing QuestionExtractionService
    Rails.logger.info("Falling back to regex-based extraction")
    service = QuestionExtractionService.new(@markdown_content)
    service.extract_questions
    service.all_questions
  end

  def match_questions_to_passages(questions_data, passages_data)
    # Questions already have passage_ids from AI extraction
    # This method can add additional matching logic if needed
    { questions: questions_data, passages: passages_data[:passages] }
  end

  def validate_extracted_questions(matched_data)
    validation_service = QuestionValidationService.new

    validated_questions = matched_data[:questions].map do |question_data|
      validation_result = validation_service.validate_question_data(question_data)
      question_data.merge(validation: validation_result)
    end

    {
      questions: validated_questions.select { |q| q[:validation][:valid] },
      passages: matched_data[:passages],
      invalid_questions: validated_questions.reject { |q| q[:validation][:valid] }
    }
  end

  def generate_extraction_stats(validated_data)
    {
      total_questions: validated_data[:questions].size,
      total_passages: validated_data[:passages].size,
      questions_with_passages: validated_data[:questions].count { |q| q[:passage_ids].present? },
      questions_without_passages: validated_data[:questions].count { |q| q[:passage_ids].blank? },
      invalid_questions: validated_data[:invalid_questions]&.size || 0,
      question_types: validated_data[:questions].group_by { |q| q[:question_type] }.transform_values(&:count),
      avg_difficulty: validated_data[:questions].map { |q| q[:difficulty] || 3 }.sum.to_f / [validated_data[:questions].size, 1].max,
      avg_confidence: validated_data[:questions].map { |q| q[:confidence_score] || 0 }.sum.to_f / [validated_data[:questions].size, 1].max
    }
  end
end
