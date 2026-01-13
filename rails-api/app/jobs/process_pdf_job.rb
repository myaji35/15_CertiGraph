class ProcessPdfJob < ApplicationJob
  queue_as :default

  def perform(study_material_id)
    study_material = StudyMaterial.find(study_material_id)
    return unless study_material.pdf_file.attached?

    begin
      # 상태를 처리중으로 업데이트
      study_material.update(status: 'processing')

      # PDF 파일을 임시 파일로 다운로드
      pdf_file = study_material.pdf_file

      pdf_file.open do |file|
        # PDF 파서 서비스 사용
        parser = PdfParserService.new(file.path)
        questions = parser.extract_questions

        # 지문 복제 처리
        questions = parser.process_passage_replication(questions)

        # 문제들을 청킹 (10개씩)
        chunks = parser.chunk_questions(questions, 10)

        # 결과를 JSON으로 저장
        study_material.update(
          status: 'completed',
          extracted_data: {
            total_questions: questions.length,
            chunks: chunks.length,
            questions: questions,
            processed_at: Time.current
          }
        )

        # 각 문제를 Question 모델로 저장
        questions.each do |q|
          Question.create!(
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
end