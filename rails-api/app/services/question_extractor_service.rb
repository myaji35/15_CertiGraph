# frozen_string_literal: true

require 'openai'

class QuestionExtractorService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    raise 'OPENAI_API_KEY is not set' if ENV['OPENAI_API_KEY'].blank?
  end

  # Extract questions from text using GPT-4o
  def extract_questions_from_text(text, study_material_id)
    Rails.logger.info "Extracting questions from text (#{text.length} characters)"
    
    prompt = build_extraction_prompt(text)
    
    response = @client.chat(
      parameters: {
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: system_prompt },
          { role: 'user', content: prompt }
        ],
        temperature: 0.3,
        response_format: { type: 'json_object' }
      }
    )

    questions_data = parse_response(response)
    create_questions(questions_data, study_material_id)
    
  rescue StandardError => e
    Rails.logger.error "Question extraction failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise StandardError, "문제 추출 실패: #{e.message}"
  end

  private

  def system_prompt
    <<~PROMPT
      당신은 한국어 시험 문제 추출 전문가입니다.
      주어진 텍스트에서 객관식 문제를 정확히 추출하고 JSON 형식으로 반환합니다.

      반환 형식:
      {
        "questions": [
          {
            "content": "문제 내용 (문제 번호 제외)",
            "options": ["선택지1", "선택지2", "선택지3", "선택지4", "선택지5"],
            "correct_answer_index": 0,
            "difficulty": 3,
            "topic": "주제 분류",
            "explanation": "해설 (있는 경우)",
            "has_passage": false,
            "passage_content": "지문 내용 (있는 경우)"
          }
        ]
      }

      규칙:
      1. 문제 번호는 content에서 제외 (예: "1." 제거)
      2. 선택지는 번호 없이 내용만 (예: "①" 제거)
      3. correct_answer_index는 0-based (0, 1, 2, 3, 4)
      4. difficulty는 1-5 사이 (1: 쉬움, 5: 어려움)
      5. topic은 문제의 주제 분류 (예: "사회복지실천", "인간행동과 사회환경")
      6. has_passage는 지문이 있으면 true
      7. 선택지가 5개 미만이면 빈 문자열로 채우기
    PROMPT
  end

  def build_extraction_prompt(text)
    <<~PROMPT
      다음 텍스트에서 모든 객관식 문제를 추출해주세요:

      #{text}

      위 텍스트에서 문제, 선택지, 정답을 추출하여 JSON 형식으로 반환해주세요.
      문제 번호와 선택지 번호는 제거하고 내용만 추출하세요.
    PROMPT
  end

  def parse_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    data = JSON.parse(content)
    data['questions'] || []
  end

  def create_questions(questions_data, study_material_id)
    study_material = StudyMaterial.find(study_material_id)
    created_questions = []

    questions_data.each_with_index do |q_data, index|
      question = Question.create!(
        study_material_id: study_material_id,
        content: q_data['content'],
        question_type: 'multiple_choice',
        difficulty: q_data['difficulty'] || 3,
        topic: q_data['topic'],
        explanation: q_data['explanation'],
        position: index + 1,
        has_passage: q_data['has_passage'] || false
      )

      # Create passage if exists
      if q_data['has_passage'] && q_data['passage_content'].present?
        passage = Passage.create!(
          study_material_id: study_material_id,
          content: q_data['passage_content'],
          passage_type: 'text',
          position: index
        )
        
        QuestionPassage.create!(
          question_id: question.id,
          passage_id: passage.id,
          is_primary: true
        )
      end

      # Create options (ensure 5 options)
      options = q_data['options'] || []
      options = options.first(5) # Take first 5
      options += [''] * (5 - options.length) if options.length < 5 # Pad to 5

      options.each_with_index do |option_content, opt_index|
        next if option_content.blank?
        
        Option.create!(
          question_id: question.id,
          content: option_content,
          is_correct: (opt_index == q_data['correct_answer_index'])
        )
      end

      created_questions << question
    end

    Rails.logger.info "Created #{created_questions.count} questions"
    created_questions
  end
end
