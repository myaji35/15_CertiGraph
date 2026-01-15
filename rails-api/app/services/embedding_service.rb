class EmbeddingService
  # 문서 청크와 질문을 임베딩하는 서비스
  # - 청크 단위 임베딩 생성
  # - 배치 처리 지원
  # - 매그니튜드 계산 및 저장

  CHUNK_SIZE = 512       # 청크 크기 (토큰)
  CHUNK_OVERLAP = 64     # 청크 간 오버랩 (토큰)
  MODEL = "text-embedding-3-small"
  EMBEDDING_DIMENSION = 1536

  def initialize
    @openai_client = OpenaiClient.new
  end

  # 문서를 청크로 분할하고 임베딩 생성
  # @param study_material [StudyMaterial] 학습 자료
  # @return [Integer] 생성된 임베딩 수
  def generate_embeddings_for_document(study_material)
    return 0 if study_material.blank?

    begin
      Rails.logger.info("Starting embedding generation for study_material: #{study_material.id}")

      # 청크 생성
      chunks = create_document_chunks(study_material)
      return 0 if chunks.blank?

      Rails.logger.info("Created #{chunks.size} chunks for study_material: #{study_material.id}")

      # 배치 임베딩 생성 및 저장
      embedding_count = generate_and_save_embeddings(chunks)

      Rails.logger.info("Generated #{embedding_count} embeddings for study_material: #{study_material.id}")

      embedding_count
    rescue StandardError => e
      Rails.logger.error("Error generating embeddings for study_material #{study_material.id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise e
    end
  end

  # 단일 텍스트의 임베딩 생성
  # @param text [String] 임베딩할 텍스트
  # @return [Array<Float>] 임베딩 벡터
  def generate_embedding(text)
    return nil if text.blank?

    @openai_client.generate_embedding(text)
  rescue StandardError => e
    Rails.logger.error("Error generating single embedding: #{e.message}")
    nil
  end

  # 질문의 임베딩 생성 및 저장
  # @param question [Question] 질문
  # @return [Boolean] 성공 여부
  def generate_embedding_for_question(question)
    return false if question.blank?

    begin
      # 임베딩할 텍스트 준비
      text = prepare_question_text(question)
      return false if text.blank?

      # 임베딩 생성
      embedding_vector = generate_embedding(text)
      return false if embedding_vector.blank?

      # 질문에 임베딩 저장
      question.update!(
        embedding: embedding_vector,
        embedding_generated_at: Time.current
      )

      true
    rescue StandardError => e
      Rails.logger.error("Error generating embedding for question #{question.id}: #{e.message}")
      false
    end
  end

  private

  # 문서를 청크로 분할
  # @param study_material [StudyMaterial]
  # @return [Array<DocumentChunk>]
  def create_document_chunks(study_material)
    text = extract_text_from_study_material(study_material)
    return [] if text.blank?

    chunks = []
    position = 0
    chunk_index = 0

    # 간단한 청킹: 토큰 단위 대신 문자 기반 청킹
    # (정확한 토큰 계산은 tiktoken 라이브러리 필요)
    chunk_char_size = CHUNK_SIZE * 4  # 대략 1 토큰 = 4 문자
    overlap_char_size = CHUNK_OVERLAP * 4

    while position < text.length
      end_position = [position + chunk_char_size, text.length].min
      chunk_text = text[position...end_position]

      # 문장 경계에서 자르기
      if end_position < text.length
        last_sentence = chunk_text.rindex(/[.!?\n]/)
        if last_sentence && last_sentence > chunk_char_size / 2
          end_position = position + last_sentence + 1
        end
      end

      # 청크 생성
      chunk = DocumentChunk.create!(
        study_material: study_material,
        content: text[position...end_position],
        token_count: estimate_token_count(text[position...end_position]),
        chunk_index: chunk_index,
        start_position: position,
        end_position: end_position,
        has_passage: text[position...end_position].include?("다음 글을 읽고"),
        passage_context: extract_passage_context(text, position)
      )

      chunks << chunk

      # 오버랩을 고려하여 다음 위치 결정
      position = end_position - overlap_char_size
      position = [position, end_position].max  # 음수 방지
      chunk_index += 1
    end

    chunks
  end

  # 배치로 임베딩 생성 및 저장
  # @param chunks [Array<DocumentChunk>]
  # @return [Integer] 생성된 임베딩 수
  def generate_and_save_embeddings(chunks)
    return 0 if chunks.blank?

    embedding_count = 0

    # 배치 크기: API 제한 고려 (최대 100개)
    batch_size = 100

    chunks.each_slice(batch_size) do |batch|
      texts = batch.map(&:content)

      begin
        embedding_vectors = @openai_client.generate_batch_embeddings(texts)

        batch.each_with_index do |chunk, idx|
          embedding_vector = embedding_vectors[idx]
          next if embedding_vector.blank?

          # 매그니튜드 계산
          magnitude = calculate_magnitude(embedding_vector)

          # 임베딩 저장
          Embedding.create!(
            document_chunk: chunk,
            vector: embedding_vector,
            magnitude: magnitude,
            generated_at: Time.current
          )

          embedding_count += 1
        end
      rescue StandardError => e
        Rails.logger.error("Error generating batch embeddings: #{e.message}")
        # 배치 실패해도 계속 진행
      end
    end

    embedding_count
  end

  # 학습 자료에서 텍스트 추출
  # @param study_material [StudyMaterial]
  # @return [String]
  def extract_text_from_study_material(study_material)
    text = []

    # 학습자료의 추출된 데이터 사용
    if study_material.extracted_data.present?
      extracted = study_material.extracted_data
      text << extracted["text"] if extracted["text"].present?

      # 문제들도 포함
      if extracted["questions"].is_a?(Array)
        extracted["questions"].each do |q|
          text << q["content"] if q["content"].present?
          if q["options"].is_a?(Array)
            q["options"].each { |opt| text << opt if opt.present? }
          end
          text << q["explanation"] if q["explanation"].present?
        end
      end
    end

    # 관련된 질문들도 포함
    study_material.questions.each do |question|
      text << question.content if question.content.present?
      if question.options.is_a?(Hash)
        question.options.each_value { |opt| text << opt if opt.present? }
      elsif question.options.is_a?(Array)
        question.options.each { |opt| text << opt if opt.present? }
      end
    end

    text.compact.join("\n\n")
  end

  # 질문의 임베딩용 텍스트 준비
  # @param question [Question]
  # @return [String]
  def prepare_question_text(question)
    parts = []

    parts << question.content if question.content.present?
    parts << question.passage if question.passage.present?

    if question.options.is_a?(Hash)
      question.options.each_value { |opt| parts << opt if opt.present? }
    elsif question.options.is_a?(Array)
      question.options.each { |opt| parts << opt if opt.present? }
    end

    parts << question.explanation if question.explanation.present?

    parts.compact.join(" ")
  end

  # 지문 컨텍스트 추출
  # @param text [String]
  # @param position [Integer]
  # @return [String]
  def extract_passage_context(text, position)
    passage_start = text.rindex("다음 글을 읽고", position) || position
    passage_text = text[passage_start...(position + 200)]
    passage_text&.truncate(500) || ""
  end

  # 토큰 수 추정 (대략치)
  # @param text [String]
  # @return [Integer]
  def estimate_token_count(text)
    return 0 if text.blank?

    # 대략적인 추정: 1 토큰 ≈ 4 문자
    (text.length / 4.0).ceil
  end

  # 벡터의 L2 매그니튜드 계산
  # @param vector [Array<Float>]
  # @return [Float]
  def calculate_magnitude(vector)
    return 1.0 if vector.blank?

    Math.sqrt(vector.sum { |v| v ** 2 })
  end
end
