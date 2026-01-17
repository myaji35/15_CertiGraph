class AutoTaggingService
  attr_reader :study_material, :client, :errors

  def initialize(study_material)
    @study_material = study_material
    @client = OpenaiClient.new
    @errors = []
  end

  def generate_tags
    return false unless valid_for_tagging?

    begin
      # Extract tags using AI
      ai_tags = extract_tags_with_ai

      # Extract tags using keyword analysis
      keyword_tags = extract_tags_with_keywords

      # Combine and deduplicate tags
      all_tags = (ai_tags + keyword_tags).uniq { |t| t[:name].downcase }

      # Apply tags to study material
      apply_tags(all_tags)

      true
    rescue StandardError => e
      @errors << "Auto-tagging failed: #{e.message}"
      Rails.logger.error("AutoTaggingService Error: #{e.message}\n#{e.backtrace.join("\n")}")
      false
    end
  end

  def self.tag_batch(study_materials)
    results = { success: [], failed: [] }

    study_materials.each do |material|
      service = new(material)
      if service.generate_tags
        results[:success] << material
      else
        results[:failed] << { material: material, errors: service.errors }
      end
    end

    results
  end

  private

  def valid_for_tagging?
    if study_material.nil?
      @errors << "Study material is nil"
      return false
    end

    unless study_material.status == 'completed'
      @errors << "Study material must be in 'completed' status"
      return false
    end

    true
  end

  def extract_tags_with_ai
    return [] unless @client

    content = content_for_tagging

    prompt = build_tagging_prompt(content)

    response = @client.chat_completion(
      messages: [
        { role: 'system', content: system_prompt },
        { role: 'user', content: prompt }
      ],
      model: 'gpt-4o-mini',
      temperature: 0.5,
      max_tokens: 800
    )

    if response['error']
      Rails.logger.warn("AI tagging failed: #{response['error']}")
      return []
    end

    parse_tagging_response(response['content'])
  rescue StandardError => e
    Rails.logger.error("AI tagging error: #{e.message}")
    []
  end

  def extract_tags_with_keywords
    tags = []
    content = content_for_tagging.downcase

    # Topic-based tags
    TOPIC_KEYWORDS.each do |tag_name, keywords|
      if keywords.any? { |keyword| content.include?(keyword.downcase) }
        tags << {
          name: tag_name,
          context: 'topic',
          relevance_score: 80
        }
      end
    end

    # Difficulty-based tags
    if study_material.difficulty
      difficulty_tag = case study_material.difficulty
      when 1..2
        '초급'
      when 3
        '중급'
      when 4..5
        '고급'
      end

      tags << {
        name: difficulty_tag,
        context: 'difficulty',
        relevance_score: 100
      } if difficulty_tag
    end

    # Year-based tag
    if study_material.content_metadata&.dig(:exam_year)
      tags << {
        name: "#{study_material.content_metadata[:exam_year]}년",
        context: 'year',
        relevance_score: 100
      }
    end

    # Category-based tag
    if study_material.category
      category_kr = ContentClassificationService.category_name(study_material.category)
      tags << {
        name: category_kr,
        context: 'category',
        relevance_score: 100
      }
    end

    tags
  end

  def content_for_tagging
    content_parts = []

    content_parts << study_material.name if study_material.name.present?

    # Sample questions
    questions = study_material.questions.limit(5).pluck(:question_text)
    content_parts.concat(questions)

    # Knowledge nodes
    nodes = study_material.knowledge_nodes.limit(10).pluck(:name, :description)
    content_parts.concat(nodes.flatten.compact)

    content_parts.join("\n\n")
  end

  def system_prompt
    <<~PROMPT
      You are an expert in Korean certification exam content analysis and tagging.
      Your task is to analyze study material and generate relevant tags.

      Tags should be:
      - In Korean language
      - Specific and descriptive
      - Relevant to the content
      - Useful for search and filtering

      Tag contexts:
      - topic: Subject matter (e.g., "알고리즘", "네트워크", "데이터베이스")
      - skill: Required skills (e.g., "문제해결", "논리적사고")
      - concept: Key concepts (e.g., "객체지향", "함수형프로그래밍")
      - exam_type: Exam characteristics (e.g., "단답형", "서술형", "계산문제")

      Respond with JSON format:
      {
        "tags": [
          {
            "name": "태그이름",
            "context": "topic",
            "relevance_score": 85,
            "reasoning": "brief explanation"
          }
        ]
      }

      Generate 5-15 tags. Prioritize quality over quantity.
    PROMPT
  end

  def build_tagging_prompt(content)
    metadata_info = ""
    if study_material.content_metadata.present?
      metadata_info = "\n\n메타데이터:\n"
      metadata_info += "- 자격증: #{study_material.content_metadata[:certification_name]}\n" if study_material.content_metadata[:certification_name]
      metadata_info += "- 연도: #{study_material.content_metadata[:exam_year]}년\n" if study_material.content_metadata[:exam_year]
      metadata_info += "- 난이도: #{ContentClassificationService.difficulty_name(study_material.difficulty)}\n" if study_material.difficulty
    end

    <<~PROMPT
      다음 학습 자료를 분석하여 관련 태그를 생성해주세요:

      제목: #{study_material.name}
      카테고리: #{ContentClassificationService.category_name(study_material.category)}
      문제 수: #{study_material.questions.count}
      #{metadata_info}

      내용 샘플:
      #{content.truncate(1500)}

      위 내용을 바탕으로 검색과 필터링에 유용한 태그들을 JSON 형식으로 제공해주세요.
      각 태그에는 relevance_score (0-100)를 포함해주세요.
    PROMPT
  end

  def parse_tagging_response(content)
    # Extract JSON from response
    json_match = content.match(/```json\s*(\{.*?\})\s*```/m) || content.match(/(\{.*?\})/m)

    return [] unless json_match

    result = JSON.parse(json_match[1])
    result['tags'] || []
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse tagging response: #{e.message}")
    []
  end

  def apply_tags(tags_data)
    return if tags_data.empty?

    tags_data.each do |tag_data|
      tag = Tag.find_or_create_by_name(
        tag_data[:name] || tag_data['name'],
        category: tag_data[:context] || tag_data['context']
      )

      # Create tagging if it doesn't exist
      Tagging.find_or_create_by(
        tag: tag,
        taggable: study_material
      ) do |tagging|
        tagging.context = tag_data[:context] || tag_data['context'] || 'general'
        tagging.relevance_score = tag_data[:relevance_score] || tag_data['relevance_score'] || 50
      end
    end
  end

  # Topic keywords mapping
  TOPIC_KEYWORDS = {
    '알고리즘' => ['알고리즘', '정렬', '탐색', '재귀'],
    '네트워크' => ['네트워크', 'tcp', 'ip', '프로토콜', 'osi'],
    '데이터베이스' => ['데이터베이스', 'sql', '정규화', '트랜잭션'],
    '운영체제' => ['운영체제', '프로세스', '스레드', '메모리'],
    '자료구조' => ['자료구조', '스택', '큐', '트리', '그래프'],
    '소프트웨어공학' => ['소프트웨어공학', '설계', '테스팅', '유지보수'],
    '프로그래밍' => ['프로그래밍', '코딩', '개발', '언어'],
    '보안' => ['보안', '암호화', '인증', '방화벽'],
    '웹개발' => ['웹', 'html', 'css', 'javascript'],
    '전기이론' => ['전기', '회로', '전압', '전류', '저항'],
    '건축구조' => ['건축', '구조', '설계', '시공'],
    '소방설비' => ['소방', '화재', '소화', '경보'],
    '회계원리' => ['회계', '재무', '원가', '관리'],
    '세법' => ['세법', '세금', '과세']
  }.freeze

  # Remove all tags from study material
  def self.clear_tags(study_material)
    study_material.taggings.destroy_all
  end

  # Regenerate tags for study material
  def self.regenerate_tags(study_material)
    clear_tags(study_material)
    new(study_material).generate_tags
  end

  # Regenerate all tags
  def self.regenerate_all
    StudyMaterial.where(status: 'completed').find_each do |material|
      regenerate_tags(material)
    end
  end
end
