class ProcessPdfJob < ApplicationJob
  queue_as :pdf_processing

  # PDF 처리 특화 재시도 정책
  retry_on Timeout::Error, wait: 30.seconds, attempts: 3
  retry_on StandardError, wait: :exponentially_longer, attempts: 5

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)
    return unless study_material.pdf_file.attached?

    begin
      # 상태를 처리중으로 업데이트
      study_material.update(status: 'processing', parsing_progress: 10)

      # PDF 파일을 임시 파일로 다운로드
      pdf_file = study_material.pdf_file

      pdf_file.open do |file|
        # Phase 2: Upstage OCR + GPT-4o (AI-powered extraction)
        if use_ai_extraction?
          Rails.logger.info "🤖 Using AI Extraction (Upstage OCR + GPT-4o)"
          process_with_ai(study_material, file.path)
        else
          # Fallback: Python Algorithm (Option C)
          Rails.logger.info "🐍 Using Python Algorithm Parser (NO AI, NO API Cost)"
          process_with_python(study_material, file.path)
        end

        Rails.logger.info "Successfully processed PDF: #{study_material.id}"
      end
    rescue => e
      Rails.logger.error "Failed to process PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      study_material.update(
        status: 'failed',
        error_message: e.message,
        parsing_progress: 0
      )
    end
  end

  private

  def use_ai_extraction?
    # Use AI if API keys are configured
    ENV['UPSTAGE_API_KEY'].present? && ENV['OPENAI_API_KEY'].present?
  end

  def process_with_ai(study_material, pdf_path)
    # Step 1: Extract text with Upstage OCR
    Rails.logger.info "Step 1/3: Extracting text with Upstage OCR"
    ocr_service = UpstageOcrService.new
    ocr_result = ocr_service.extract_text_from_pdf(pdf_path)
    
    extracted_text = ocr_result[:text]
    study_material.update!(
      extracted_data: extracted_text,
      parsing_progress: 50,
      content_metadata: ocr_result[:metadata]
    )

    # Step 2: Extract questions with GPT-4o
    Rails.logger.info "Step 2/3: Extracting questions with GPT-4o"
    extractor_service = QuestionExtractorService.new
    questions = extractor_service.extract_questions_from_text(extracted_text, study_material.id)
    
    study_material.update!(parsing_progress: 80)

    # Step 3: Build Knowledge Graph (optional)
    if ENV['ENABLE_KNOWLEDGE_GRAPH'] == 'true'
      Rails.logger.info "Step 3/3: Building Knowledge Graph"
      # Knowledge Graph building will be implemented in Week 2
    end

    # Mark as completed
    study_material.update!(
      status: 'completed',
      parsing_progress: 100,
      graph_built: false
    )

    Rails.logger.info "✅ AI Extraction complete: #{questions.count} questions created"
  end

  def process_with_python(study_material, pdf_path)
    python_parser = PythonParserBridge.new(pdf_path)
    processing_result = python_parser.parse

    unless processing_result[:success]
      raise "Python parser failed: #{processing_result[:error]}"
    end

    questions = processing_result[:questions]

    # 청킹 (10개씩)
    chunks = chunk_questions(questions, 10)

    # 결과를 JSON으로 저장
    study_material.update(
      status: 'completed',
      extracted_data: {
        total_questions: questions.length,
        chunks: chunks.length,
        questions: questions,
        markdown: nil,
        images: [],
        metadata: processing_result[:metadata] || {},
        processed_at: Time.current,
        parser_version: 'python_algorithm_v2'
      }
    )

    # Question 모델로 저장 및 검증
    validator = QuestionValidationService.new
    created_count = 0
    failed_count = 0

    questions.each do |q|
      # Validate before creating
      validation = validator.validate_question_data(q)

      unless validation[:valid]
        Rails.logger.warn "Question #{q[:question_number]} validation failed: #{validation[:errors]}"
        failed_count += 1
        next
      end

      begin
        question = Question.create!(
          study_material: study_material,
          content: q[:content],
          options: q[:options],
          answer: q[:answer],  # Will be nil (manual entry required)
          explanation: q[:explanation],  # Will be nil
          passage: q[:passage],
          question_number: q[:question_number],
          topic: q[:topic] || extract_topic_from_question(q[:content]),
          difficulty: q[:difficulty] || estimate_difficulty_from_content(q[:content]),
          validation_status: 'validated'
        )
        created_count += 1

        # 각 문제에 대해 임베딩 생성 작업 큐에 추가 (선택적)
        # GenerateEmbeddingJob.perform_later(question.id)
      rescue => e
        Rails.logger.error "Failed to create question #{q[:question_number]}: #{e.message}"
        failed_count += 1
      end
    end

    Rails.logger.info "✅ Questions created: #{created_count}, failed: #{failed_count}"
  end


  def convert_options_to_hash(options_array)
    return {} unless options_array.is_a?(Array)

    hash = {}
    options_array.each_with_index do |option, index|
      if option.is_a?(Hash) && option[:number] && option[:text]
        # 이미 구조화된 옵션
        option_key = ["①", "②", "③", "④", "⑤"][option[:number] - 1]
        hash[option_key] = option[:text]
      elsif option.is_a?(String)
        # 단순 문자열 배열인 경우
        option_key = ["①", "②", "③", "④", "⑤"][index]
        hash[option_key] = option
      end
    end
    hash
  end

  def extract_topic_from_question(text)
    # 문제 텍스트에서 주제 추출 (간단한 키워드 기반)
    topics = {
      '사회복지정책' => ['정책', '제도', '법률', '복지국가'],
      '사회복지행정' => ['행정', '관리', '조직', '리더십'],
      '인간행동과 사회환경' => ['발달', '성격', '이론', '환경'],
      '사회복지실천' => ['실천', '개입', '사정', '면접'],
      '지역사회복지' => ['지역', '주민', '조직화', '자원']
    }

    topics.each do |topic, keywords|
      keywords.each do |keyword|
        return topic if text&.include?(keyword)
      end
    end

    '일반'
  end

  def estimate_difficulty(question)
    # 문제 난이도 추정 (간단한 휴리스틱)
    text = question[:question_text].to_s
    options = question[:options] || []

    # 긴 지문이나 많은 옵션은 어려운 문제로 분류
    if text.length > 500 || options.length > 4
      'hard'
    elsif text.length > 200
      'medium'
    else
      'easy'
    end
  end

  def estimate_difficulty_from_content(content)
    return 'medium' if content.blank?

    if content.length > 500
      'hard'
    elsif content.length > 200
      'medium'
    else
      'easy'
    end
  end

  def chunk_questions(questions, chunk_size)
    questions.each_slice(chunk_size).to_a
  end

  def extract_images_with_captions(pdf_path)
    begin
      image_service = ImageExtractionService.new(pdf_path)
      result = image_service.extract_and_caption

      # 처리 후 임시 파일 정리
      image_service.cleanup if result[:success]

      result
    rescue StandardError => e
      Rails.logger.warn("Image extraction failed: #{e.message}")
      { success: false, images: [], error: e.message }
    end
  end
end