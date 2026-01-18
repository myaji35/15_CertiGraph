# frozen_string_literal: true

require 'openai'

class QuestionExtractorService
  def initialize
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  # Extract questions from text using GPT-4o
  def extract_questions(text, study_set_id)
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

    parse_and_create_questions(response, study_set_id)
  rescue StandardError => e
    Rails.logger.error "Question extraction failed: #{e.message}"
    raise "문제 추출 실패: #{e.message}"
  end

  private

  def system_prompt
    <<~PROMPT
      당신은 한국어 시험 문제 추출 전문가입니다.
      주어진 텍스트에서 객관식 문제를 추출하고 JSON 형식으로 반환합니다.

      반환 형식:
      {
        "questions": [
          {
            "content": "문제 내용",
            "options": ["선택지1", "선택지2", "선택지3", "선택지4"],
            "correct_answer": 0,
            "difficulty": 3,
            "topic": "주제",
            "explanation": "해설"
          }
        ]
      }

      규칙:
      1. 문제와 선택지를 정확히 추출
      2. correct_answer는 0-based index (0, 1, 2, 3)
      3. difficulty는 1-5 사이 (1: 쉬움, 5: 어려움)
      4. topic은 문제의 주제 분류
      5. explanation은 정답 해설 (있는 경우)
    PROMPT
  end

  def build_extraction_prompt(text)
    <<~PROMPT
      다음 텍스트에서 모든 객관식 문제를 추출해주세요:

      #{text}

      위 텍스트에서 문제, 선택지, 정답을 추출하여 JSON 형식으로 반환해주세요.
    PROMPT
  end

  def parse_and_create_questions(response, study_set_id)
    content = response.dig('choices', 0, 'message', 'content')
    data = JSON.parse(content)
    
    questions_data = data['questions'] || []
    created_questions = []

    questions_data.each do |q_data|
      question = Question.create!(
        study_set_id: study_set_id,
        content: q_data['content'],
        question_type: 'multiple_choice',
        difficulty: q_data['difficulty'] || 3,
        topic: q_data['topic'],
        explanation: q_data['explanation'],
        correct_answer: q_data['correct_answer']
      )

      # Create options
      q_data['options'].each_with_index do |option_content, index|
        question.options.create!(
          content: option_content,
          is_correct: (index == q_data['correct_answer'])
        )
      end

      created_questions << question
    end

    created_questions
  end
end
