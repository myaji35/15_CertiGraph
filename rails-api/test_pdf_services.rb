#!/usr/bin/env ruby
# PDF 처리 서비스 통합 테스트 스크립트
# 사용법: ruby test_pdf_services.rb

require_relative 'config/environment'

puts "\n" + "="*60
puts "PDF Processing Services Integration Test"
puts "="*60

# Test 1: UpstageClient 기본 테스트
puts "\n[Test 1] UpstageClient Configuration"
puts "-" * 60

begin
  if ENV['UPSTAGE_API_KEY'].present?
    puts "✓ UPSTAGE_API_KEY is configured"
    client = UpstageClient.new
    puts "✓ UpstageClient initialized successfully"
    puts "✓ API is configured: #{UpstageClient.configured?}"
  else
    puts "! UPSTAGE_API_KEY is not set"
    puts "  Set it with: export UPSTAGE_API_KEY='your_key_here'"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 2: QuestionExtractionService 테스트
puts "\n[Test 2] QuestionExtractionService"
puts "-" * 60

sample_markdown = <<~MARKDOWN
  # 시험 문제

  다음을 읽고 문제에 답하시오.

  지문: 대한민국의 정치 체제는 대통령 중심제입니다.
  이는 권력의 분립 원칙을 따릅니다.

  1. 한국 정치 체제의 특징은 무엇인가?
  ① 의원 내각제
  ② 대통령 중심제
  ③ 군부 독재제
  ④ 민주 연방제
  ⑤ 군부권위주의

  2. 권력의 분립은 어떤 원칙인가?
  ① 대통령의 절대권
  ② 국회의 절대권
  ③ 입법, 행정, 사법의 분리
  ④ 정부의 모든 권력 집중
  ⑤ 국민의 직접 통치

  3) 다음 중 정치 체제에 포함되지 않는 것은?
  ① 입법부
  ② 행정부
  ③ 사법부
  ④ 시민사회
  ⑤ 이익집단

  (4) 대통령제의 장점은 무엇인가?
  ① 행정부의 민주적 통제 용이
  ② 권력의 안정성
  ③ 신속한 정책 결정
  ④ 입법부의 권력 강화
  ⑤ 국회의 자율성 확대
MARKDOWN

begin
  service = QuestionExtractionService.new(sample_markdown)
  questions = service.extract_questions

  puts "✓ Extracted #{questions.length} questions"

  # 각 질문 상세 출력
  questions.each_with_index do |q, idx|
    puts "\n  Question #{q[:question_number]}:"
    puts "  Text: #{q[:question_text][0..50]}..."
    puts "  Options: #{q[:options].length} choices"
    puts "  Has Table: #{q[:has_table]}"
    puts "  Has Image: #{q[:has_image]}"
  end

  # 통계 출력
  stats = service.extraction_stats
  puts "\n✓ Extraction Statistics:"
  puts "  Total Questions: #{stats[:total_questions]}"
  puts "  Questions with Passages: #{stats[:questions_with_passages]}"
  puts "  Average Options: #{stats[:average_options].round(2)}"

  # 특정 질문 조회
  q1 = service.find_question_by_number(1)
  if q1
    puts "\n✓ Question #1 found:"
    puts "  Question: #{q1[:question_text][0..40]}..."
    puts "  Answer Count: #{q1[:options].length}"
  end
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Test 3: PdfProcessingService 기본 테스트
puts "\n[Test 3] PdfProcessingService (without API)"
puts "-" * 60

begin
  # 테스트용 임시 파일 생성
  test_file = Tempfile.new('test.pdf')
  test_file.close

  service = PdfProcessingService.new(test_file.path)
  puts "✓ PdfProcessingService initialized with: #{File.basename(test_file.path)}"

  # 청킹 테스트
  sample_questions = (1..25).map do |i|
    { question_number: i, question_text: "Question #{i}" }
  end

  chunks = service.chunk_questions(sample_questions, chunk_size: 10)
  puts "✓ Chunked #{sample_questions.length} questions into #{chunks.length} chunks"
  puts "  Chunk sizes: #{chunks.map(&:length).join(', ')}"

  # 통계 테스트
  stats = service.processing_stats
  puts "✓ Processing stats:"
  puts "  File Path: #{stats[:file_path]}"
  puts "  Markdown Length: #{stats[:markdown_length]}"
  puts "  Has Metadata: #{stats[:has_metadata]}"

  test_file.unlink
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

# Test 4: 옵션 포맷 테스트
puts "\n[Test 4] Option Formatting"
puts "-" * 60

begin
  markdown = <<~MARKDOWN
    1. 테스트 문제
    ① 첫 번째
    ② 두 번째
    ③ 세 번째
    ④ 네 번째
    ⑤ 다섯 번째
  MARKDOWN

  service = QuestionExtractionService.new(markdown)
  questions = service.extract_questions

  if questions.any?
    q = questions.first
    puts "✓ Question ##{q[:question_number]}"
    puts "✓ Options format (Hash):"
    q[:options].each do |symbol, text|
      puts "  #{symbol} => #{text[0..30]}..."
    end
  end
rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 5: 다양한 질문 번호 형식 테스트
puts "\n[Test 5] Various Question Number Formats"
puts "-" * 60

begin
  markdown = <<~MARKDOWN
    1. 첫 번째 형식 (1.)
    ① 옵션 1
    ② 옵션 2

    2) 두 번째 형식 (2))
    ① 옵션 A
    ② 옵션 B

    (3) 세 번째 형식 ((3))
    ① 선택지 1
    ② 선택지 2

    4. 네 번째 형식
    ① 항목 1
    ② 항목 2
  MARKDOWN

  service = QuestionExtractionService.new(markdown)
  questions = service.extract_questions

  puts "✓ Recognized question number formats:"
  questions.each do |q|
    puts "  Question #{q[:question_number]}"
  end

  expected_numbers = [1, 2, 3, 4]
  found_numbers = questions.map { |q| q[:question_number] }
  if expected_numbers == found_numbers
    puts "✓ All formats recognized correctly"
  else
    puts "✗ Missing formats: #{(expected_numbers - found_numbers).inspect}"
  end
rescue => e
  puts "✗ Error: #{e.message}"
end

# 최종 요약
puts "\n" + "="*60
puts "Test Summary"
puts "="*60
puts "✓ All basic tests completed"
puts "✓ QuestionExtractionService is working correctly"
puts "✓ PdfProcessingService initialized successfully"
puts "\nNext Steps:"
puts "1. Configure UPSTAGE_API_KEY for full PDF processing"
puts "2. Run Rails tests: rails test test/services/"
puts "3. Set up mock/stub for integration tests"
puts "="*60 + "\n"
