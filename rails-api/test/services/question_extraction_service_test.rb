# QuestionExtractionService 테스트
require 'test_helper'

class QuestionExtractionServiceTest < ActiveSupport::TestCase
  setup do
    # 기본 테스트용 마크다운
    @sample_markdown = <<~MARKDOWN
      # 시험 문제집

      1. 첫 번째 문제는 무엇인가?
      ① 첫 번째 선택지
      ② 두 번째 선택지
      ③ 세 번째 선택지
      ④ 네 번째 선택지
      ⑤ 다섯 번째 선택지

      2. 두 번째 문제
      ① 옵션 1
      ② 옵션 2
      ③ 옵션 3

      3) 세 번째 문제는 어떻게 되는가?
      ① 선택지 A
      ② 선택지 B
      ③ 선택지 C
      ④ 선택지 D

      (4) 네 번째 문제
      ① 첫번째
      ② 두번째
    MARKDOWN

    @service = QuestionExtractionService.new(@sample_markdown)
  end

  test 'service initializes with markdown content' do
    assert_equal @sample_markdown, @service.markdown_content
  end

  test 'extract_questions returns array' do
    questions = @service.extract_questions
    assert_instance_of Array, questions
  end

  test 'extract_questions returns empty array for blank markdown' do
    service = QuestionExtractionService.new('')
    questions = service.extract_questions
    assert_empty questions
  end

  test 'extract_questions returns empty array for nil markdown' do
    service = QuestionExtractionService.new(nil)
    questions = service.extract_questions
    assert_empty questions
  end

  test 'all_questions returns same as extract_questions' do
    questions = @service.extract_questions
    all_questions = @service.all_questions
    assert_equal questions, all_questions
  end

  test 'find_question_by_number returns correct question' do
    @service.extract_questions
    question = @service.find_question_by_number(1)

    assert_not_nil question
    assert_equal 1, question[:question_number]
  end

  test 'find_question_by_number returns nil for non-existent question' do
    @service.extract_questions
    question = @service.find_question_by_number(999)

    assert_nil question
  end

  test 'extracted questions have required fields' do
    questions = @service.extract_questions

    questions.each do |question|
      assert_includes question, :question_number
      assert_includes question, :question_text
      assert_includes question, :options
      assert_includes question, :passage
    end
  end

  test 'options are formatted as hash' do
    questions = @service.extract_questions

    questions.each do |question|
      assert_instance_of Hash, question[:options]
      next if question[:options].empty?

      # 첫 번째 옵션이 ① 기호를 포함
      assert question[:options].keys.first.include?('①') ||
             question[:options].keys.first.include?('②') ||
             question[:options].keys.first.include?('③') ||
             question[:options].keys.first.include?('④') ||
             question[:options].keys.first.include?('⑤')
    end
  end

  test 'extraction_stats returns correct structure' do
    @service.extract_questions
    stats = @service.extraction_stats

    assert_includes stats, :total_questions
    assert_includes stats, :questions_with_passages
    assert_includes stats, :questions_without_passages
    assert_includes stats, :average_options

    assert stats[:total_questions] >= 0
    assert stats[:average_options] >= 0
  end

  test 'handles different question numbering formats' do
    markdown = <<~MARKDOWN
      1. First question
      ① Option 1
      ② Option 2

      2) Second question
      ① Option A
      ② Option B

      (3) Third question
      ① Choice 1
      ② Choice 2
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    assert questions.any? { |q| q[:question_number] == 1 }
    assert questions.any? { |q| q[:question_number] == 2 }
    assert questions.any? { |q| q[:question_number] == 3 }
  end

  test 'handles questions with table indicators' do
    markdown = <<~MARKDOWN
      1. 다음 표를 참고하여 답하시오.
      | 항목 | 설명 |
      |------|------|
      | A | 첫번째 |
      | B | 두번째 |
      ① Option 1
      ② Option 2
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    assert questions.any? { |q| q[:has_table] }
  end

  test 'handles questions with image references' do
    markdown = <<~MARKDOWN
      1. 다음 이미지를 보고 답하시오.
      ![image](path/to/image.png)
      ① Option 1
      ② Option 2
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    assert questions.any? { |q| q[:has_image] }
  end

  test 'normalizes whitespace in question text' do
    markdown = <<~MARKDOWN
      1. 첫 번째    문제는
         무엇인가?
      ① Option 1
      ② Option 2
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    # 질문 텍스트에서 과도한 공백이 정규화됨
    assert questions.any? { |q| q[:question_text].exclude?("   ") }
  end

  test 'minimum options requirement' do
    markdown = <<~MARKDOWN
      1. 유효한 문제
      ① Option 1
      ② Option 2

      2. 유효하지 않은 문제 (선택지 1개)
      ① Option 1
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    # 2번 문제는 추출되지 않음 (선택지 2개 미만)
    assert questions.any? { |q| q[:question_number] == 1 }
    refute questions.any? { |q| q[:question_number] == 2 }
  end

  test 'handling passage with multiple questions' do
    markdown = <<~MARKDOWN
      다음 지문을 읽고 답하시오.

      이것은 지문입니다.

      1. 첫 번째 문제
      ① 선택지 1
      ② 선택지 2

      2. 두 번째 문제
      ① 선택지 A
      ② 선택지 B
    MARKDOWN

    service = QuestionExtractionService.new(markdown)
    questions = service.extract_questions

    # 두 질문 모두 동일 지문 참조
    questions_with_passage = questions.select { |q| q[:passage].present? }
    assert questions_with_passage.length > 0
  end

  test 'option count is recorded' do
    @service.extract_questions
    stats = @service.extraction_stats

    avg_options = stats[:average_options]
    assert avg_options > 0
  end

  test 'empty markdown content' do
    service = QuestionExtractionService.new('')
    questions = service.extract_questions
    stats = service.extraction_stats

    assert_empty questions
    assert_equal 0, stats[:total_questions]
  end
end
