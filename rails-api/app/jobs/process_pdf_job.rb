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
      study_material.update(status: 'processing')

      # PDF 파일을 임시 파일로 다운로드
      pdf_file = study_material.pdf_file

      pdf_file.open do |file|
        # 1. PDF 처리 서비스로 마크다운 변환 및 문제 추출
        processing_service = PdfProcessingService.new(file.path)
        processing_result = processing_service.process

        unless processing_result[:success]
          raise "PDF processing failed: #{processing_result[:error]}"
        end

        questions = processing_result[:questions]
        markdown = processing_result[:markdown]

        # 2. 이미지 추출 및 캡션 생성 (선택적)
        image_result = extract_images_with_captions(file.path)

        # 3. 문제들을 청킹 (10개씩)
        chunks = chunk_questions(questions, 10)

        # 4. 결과를 JSON으로 저장
        study_material.update(
          status: 'completed',
          extracted_data: {
            total_questions: questions.length,
            chunks: chunks.length,
            questions: questions,
            markdown: markdown,
            images: image_result[:images] || [],
            metadata: processing_result[:metadata] || {},
            processed_at: Time.current
          }
        )

        # 각 문제를 Question 모델로 저장
        questions.each do |q|
          question = Question.create!(
            study_material: study_material,
            content: q[:question_text],
            options: convert_options_to_hash(q[:options]),
            answer: q[:correct_answer],
            explanation: q[:explanation],
            passage: q[:passage],
            question_number: q[:question_number],
            topic: extract_topic_from_question(q[:question_text]),
            difficulty: estimate_difficulty(q)
          )

          # 각 문제에 대해 임베딩 생성 작업 큐에 추가
          GenerateEmbeddingJob.perform_later(question.id)
        end

        Rails.logger.info "Successfully processed PDF: #{study_material.id}, Questions: #{questions.length}"
      end
    rescue => e
      Rails.logger.error "Failed to process PDF: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      study_material.update(
        status: 'failed',
        error_message: e.message
      )
    end
  end

  private

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