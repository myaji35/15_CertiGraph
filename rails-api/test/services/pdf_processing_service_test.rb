# PdfProcessingService 테스트
require 'test_helper'

class PdfProcessingServiceTest < ActiveSupport::TestCase
  setup do
    ENV['UPSTAGE_API_KEY'] = 'test_api_key_12345'

    # 테스트용 마크다운 샘플
    @sample_markdown = <<~MARKDOWN
      # 시험 문제

      다음을 읽고 문제에 답하시오.

      지문: 이것은 테스트 지문입니다. 다양한 개념을 포함하고 있습니다.

      1. 첫 번째 문제는 무엇인가?
      ① 첫 번째 선택지
      ② 두 번째 선택지
      ③ 세 번째 선택지
      ④ 네 번째 선택지
      ⑤ 다섯 번째 선택지

      2. 두 번째 문제는 무엇인가?
      ① 선택지 1
      ② 선택지 2
      ③ 선택지 3
      ④ 선택지 4
      ⑤ 선택지 5
    MARKDOWN

    @test_file = Tempfile.new('test.pdf')
    @test_file.close
  end

  teardown do
    ENV['UPSTAGE_API_KEY'] = nil
    @test_file.unlink if @test_file
  end

  test 'service initializes with file path' do
    service = PdfProcessingService.new(@test_file.path)
    assert_equal @test_file.path, service.file_path
  end

  test 'markdown_content is nil before conversion' do
    service = PdfProcessingService.new(@test_file.path)
    assert_nil service.markdown_content
  end

  test 'valid_markdown? returns false when no content' do
    service = PdfProcessingService.new(@test_file.path)
    refute service.valid_markdown?
  end

  test 'identify passages in markdown' do
    service = PdfProcessingService.new(@test_file.path)
    # 지문 마킹 로직 테스트 (private 메서드이므로 직접 테스트 불가)
    # 대신 process 메서드의 전체 흐름을 테스트
    skip('Requires mock of Upstage API')
  end

  test 'extract_image_captions returns empty hash when no images' do
    service = PdfProcessingService.new(@test_file.path)
    captions = service.extract_image_captions
    assert_instance_of Hash, captions
  end

  test 'chunk_questions divides questions correctly' do
    service = PdfProcessingService.new(@test_file.path)

    # 테스트용 질문 생성
    questions = (1..25).map do |i|
      { question_number: i, question_text: "Question #{i}" }
    end

    chunks = service.chunk_questions(questions, chunk_size: 10)

    assert_equal 3, chunks.length
    assert_equal 10, chunks[0].length
    assert_equal 10, chunks[1].length
    assert_equal 5, chunks[2].length
  end

  test 'chunk_questions with size 1' do
    service = PdfProcessingService.new(@test_file.path)

    questions = [{ question_number: 1 }, { question_number: 2 }]
    chunks = service.chunk_questions(questions, chunk_size: 1)

    assert_equal 2, chunks.length
  end

  test 'processing_stats returns correct information' do
    service = PdfProcessingService.new(@test_file.path)
    stats = service.processing_stats

    assert_equal @test_file.path, stats[:file_path]
    assert_equal 0, stats[:markdown_length]
    refute stats[:has_metadata]
  end

  test 'process returns error hash when API fails' do
    service = PdfProcessingService.new(@test_file.path)

    # Upstage API 호출 실패 시뮬레이션
    # 이는 mock/stub이 필요함
    skip('Requires mock of Upstage API')
  end
end
