class OpenaiClient
  # OpenAI API 통합 클라이언트
  # GPT-4o, GPT-4o-mini, text-embedding-3-small 모델 사용

  def initialize
    @client = OpenAI::Client.new(
      access_token: ENV.fetch('OPENAI_API_KEY', nil),
      request_timeout: 120
    )
  end

  # text-embedding-3-small으로 텍스트 임베딩 생성
  # @param text [String] 임베딩할 텍스트
  # @return [Array<Float>] 1536 차원의 임베딩 벡터
  # @raise [OpenAI::Error] API 에러 발생 시
  def generate_embedding(text)
    raise ArgumentError, "Text cannot be blank" if text.blank?

    # 토큰 수 제한 (최대 8191개)
    truncated_text = truncate_text(text, max_tokens: 8000)

    response = @client.embeddings(
      model: "text-embedding-3-small",
      input: truncated_text
    )

    embedding = response["data"]&.first&.dig("embedding")
    raise "Failed to generate embedding" if embedding.nil?

    embedding
  rescue Timeout::Error => e
    Rails.logger.error("OpenAI timeout error: #{e.message}")
    raise e
  rescue StandardError => e
    Rails.logger.error("OpenAI API error: #{e.message}")
    raise e
  end

  # 배치 텍스트들의 임베딩 생성
  # @param texts [Array<String>] 임베딩할 텍스트 배열
  # @return [Array<Array<Float>>] 임베딩 벡터 배열
  def generate_batch_embeddings(texts)
    raise ArgumentError, "Texts cannot be empty" if texts.blank?

    truncated_texts = texts.map { |text| truncate_text(text, max_tokens: 8000) }

    response = @client.embeddings(
      model: "text-embedding-3-small",
      input: truncated_texts
    )

    embeddings = response["data"].sort_by { |item| item["index"] }
                              .map { |item| item["embedding"] }
    embeddings
  rescue StandardError => e
    Rails.logger.error("OpenAI batch embedding error: #{e.message}")
    raise e
  end

  # GPT-4o를 사용한 추론 (개념 분석, 오답 원인 파악 등)
  # @param prompt [String] 프롬프트
  # @param context [String] 추가 컨텍스트
  # @param temperature [Float] 창의성 수준 (0.0~2.0)
  # @return [String] 생성된 텍스트
  def reason_with_gpt4o(prompt, context: nil, temperature: 0.7)
    messages = []
    messages << { role: "system", content: "You are a knowledgeable AI assistant helping with exam preparation and knowledge analysis." }

    if context.present?
      messages << { role: "system", content: "Context: #{context}" }
    end

    messages << { role: "user", content: prompt }

    response = @client.chat(
      model: "gpt-4o",
      messages: messages,
      temperature: temperature,
      max_tokens: 2000
    )

    response.dig("choices", 0, "message", "content")
  rescue StandardError => e
    Rails.logger.error("GPT-4o reasoning error: #{e.message}")
    raise e
  end

  # GPT-4o-mini를 사용한 간단한 작업 (빠르고 저렴함)
  # @param prompt [String] 프롬프트
  # @param temperature [Float] 창의성 수준
  # @return [String] 생성된 텍스트
  def reason_with_gpt4o_mini(prompt, temperature: 0.5)
    response = @client.chat(
      model: "gpt-4o-mini",
      messages: [
        { role: "system", content: "You are a helpful AI assistant." },
        { role: "user", content: prompt }
      ],
      temperature: temperature,
      max_tokens: 1000
    )

    response.dig("choices", 0, "message", "content")
  rescue StandardError => e
    Rails.logger.error("GPT-4o-mini reasoning error: #{e.message}")
    raise e
  end

  # GPT-4o Vision API (이미지 분석)
  # @param messages [Array<Hash>] 메시지 배열 (이미지 포함)
  # @param max_tokens [Integer] 최대 토큰 수
  # @return [Hash] API 응답
  def chat_with_vision(model: 'gpt-4o', messages:, max_tokens: 500)
    response = @client.chat(
      parameters: {
        model: model,
        messages: messages,
        max_tokens: max_tokens
      }
    )

    response
  rescue StandardError => e
    Rails.logger.error("GPT-4o Vision error: #{e.message}")
    raise e
  end

  # 설정된 API 키 검증
  # @return [Boolean] API 키가 유효한지 여부
  def api_key_valid?
    return false if ENV['OPENAI_API_KEY'].blank?

    begin
      # 간단한 임베딩 요청으로 API 키 검증
      @client.embeddings(
        model: "text-embedding-3-small",
        input: "test"
      )
      true
    rescue StandardError => _e
      false
    end
  end

  private

  # 텍스트를 토큰 기준으로 자르기
  # 정확한 토큰 계산은 복잡하므로 대략적인 추정치 사용
  # (1 토큰 ≈ 4 문자)
  def truncate_text(text, max_tokens: 8000)
    max_chars = max_tokens * 4
    text[0...max_chars]
  end
end
