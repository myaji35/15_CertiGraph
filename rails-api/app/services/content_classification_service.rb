class ContentClassificationService
  CATEGORIES = {
    'information_processing' => '정보처리',
    'electrical' => '전기',
    'architecture' => '건축',
    'fire_safety' => '소방',
    'hazardous_materials' => '위험물',
    'accounting' => '회계',
    'taxation' => '세무',
    'finance' => '금융',
    'real_estate' => '부동산',
    'construction' => '건설',
    'environment' => '환경',
    'safety' => '안전',
    'quality' => '품질',
    'logistics' => '물류',
    'other' => '기타'
  }.freeze

  DIFFICULTY_LEVELS = {
    1 => '매우 쉬움',
    2 => '쉬움',
    3 => '보통',
    4 => '어려움',
    5 => '매우 어려움'
  }.freeze

  attr_reader :study_material, :client, :errors

  def initialize(study_material)
    @study_material = study_material
    @client = OpenaiClient.new
    @errors = []
  end

  def classify
    return false unless valid_for_classification?

    begin
      classification_result = perform_classification

      if classification_result[:success]
        update_study_material(classification_result)
        true
      else
        @errors << classification_result[:error]
        false
      end
    rescue StandardError => e
      @errors << "Classification failed: #{e.message}"
      Rails.logger.error("ContentClassificationService Error: #{e.message}\n#{e.backtrace.join("\n")}")
      false
    end
  end

  def self.classify_batch(study_materials)
    results = { success: [], failed: [] }

    study_materials.each do |material|
      service = new(material)
      if service.classify
        results[:success] << material
      else
        results[:failed] << { material: material, errors: service.errors }
      end
    end

    results
  end

  private

  def valid_for_classification?
    if study_material.nil?
      @errors << "Study material is nil"
      return false
    end

    unless study_material.status == 'completed'
      @errors << "Study material must be in 'completed' status"
      return false
    end

    if content_for_classification.blank?
      @errors << "No content available for classification"
      return false
    end

    true
  end

  def content_for_classification
    # Use extracted data or PDF filename as basis for classification
    content_parts = []

    content_parts << study_material.name if study_material.name.present?

    if study_material.extracted_data.present?
      # Get first few questions as sample
      questions = study_material.extracted_data.dig('questions') || []
      sample_questions = questions.first(3).map { |q| q['question_text'] }.compact
      content_parts.concat(sample_questions)
    end

    content_parts.join("\n\n")
  end

  def perform_classification
    prompt = build_classification_prompt

    response = @client.chat_completion(
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: prompt }
      ],
      model: 'gpt-4o-mini',
      temperature: 0.3,
      max_tokens: 500
    )

    if response['error']
      return { success: false, error: response['error'] }
    end

    parse_classification_response(response['content'])
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def system_prompt
    <<~PROMPT
      You are an expert in Korean certification exam classification.
      Your task is to analyze study material content and classify it into the appropriate category and difficulty level.

      Available categories:
      #{CATEGORIES.map { |k, v| "#{k}: #{v}" }.join("\n")}

      Difficulty levels (1-5):
      1: Very Easy (기초)
      2: Easy (초급)
      3: Medium (중급)
      4: Hard (고급)
      5: Very Hard (최상급)

      Respond with JSON format:
      {
        "category": "category_key",
        "category_kr": "한글 카테고리명",
        "difficulty": 1-5,
        "confidence": 0.0-1.0,
        "reasoning": "brief explanation in Korean",
        "keywords": ["keyword1", "keyword2", "keyword3"]
      }
    PROMPT
  end

  def build_classification_prompt
    content = content_for_classification

    <<~PROMPT
      다음 학습 자료를 분석하여 카테고리와 난이도를 분류해주세요:

      제목: #{study_material.name}

      내용 샘플:
      #{content.truncate(1000)}

      문제 수: #{study_material.questions.count}

      위 내용을 바탕으로 가장 적합한 카테고리와 난이도를 JSON 형식으로 제공해주세요.
    PROMPT
  end

  def parse_classification_response(content)
    # Extract JSON from response (handle markdown code blocks)
    json_match = content.match(/```json\s*(\{.*?\})\s*```/m) || content.match(/(\{.*?\})/m)

    if json_match
      result = JSON.parse(json_match[1])

      {
        success: true,
        category: result['category'],
        category_kr: result['category_kr'],
        difficulty: result['difficulty'],
        confidence: result['confidence'],
        reasoning: result['reasoning'],
        keywords: result['keywords'] || []
      }
    else
      { success: false, error: "Could not parse classification response" }
    end
  rescue JSON::ParserError => e
    { success: false, error: "Invalid JSON response: #{e.message}" }
  end

  def update_study_material(classification_result)
    study_material.update!(
      category: classification_result[:category],
      difficulty: classification_result[:difficulty],
      content_metadata: (study_material.content_metadata || {}).merge(
        category_kr: classification_result[:category_kr],
        classification_confidence: classification_result[:confidence],
        classification_reasoning: classification_result[:reasoning],
        classification_keywords: classification_result[:keywords],
        classified_at: Time.current.iso8601
      )
    )
  end

  # Helper method to get category display name
  def self.category_name(category_key)
    CATEGORIES[category_key] || '기타'
  end

  # Helper method to get difficulty display name
  def self.difficulty_name(level)
    DIFFICULTY_LEVELS[level] || '보통'
  end

  # Suggest category based on keywords
  def self.suggest_category(text)
    return 'other' if text.blank?

    text_lower = text.downcase

    return 'information_processing' if text_lower.match?(/정보처리|컴퓨터|프로그래밍|소프트웨어|it/)
    return 'electrical' if text_lower.match?(/전기|전자|회로|전력/)
    return 'architecture' if text_lower.match?(/건축|설계|구조/)
    return 'fire_safety' if text_lower.match?(/소방|화재|안전/)
    return 'hazardous_materials' if text_lower.match?(/위험물|화학/)
    return 'accounting' if text_lower.match?(/회계|재무/)
    return 'taxation' if text_lower.match?(/세무|세금/)
    return 'finance' if text_lower.match?(/금융|은행|보험/)
    return 'real_estate' if text_lower.match?(/부동산|공인중개/)

    'other'
  end
end
