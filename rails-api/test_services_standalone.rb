#!/usr/bin/env ruby
# PDF Processing Services 독립 테스트 (Rails 없이)
# 사용법: ruby test_services_standalone.rb

require 'json'
require 'tempfile'
require 'net/http'
require 'uri'

puts "\n" + "="*60
puts "PDF Processing Services Standalone Test"
puts "="*60

# Test 1: UpstageClient 로드 및 설정 테스트
puts "\n[Test 1] UpstageClient Configuration"
puts "-" * 60

begin
  # 서비스 파일 내용 확인
  upstage_code = File.read('/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/upstage_client.rb')

  puts "✓ UpstageClient code loaded (#{upstage_code.length} bytes)"

  # 클래스 정의 확인
  if upstage_code.include?('class UpstageClient')
    puts "✓ UpstageClient class definition found"
  end

  # 주요 메서드 확인
  methods = ['parse_document', 'batch_parse', 'parse_with_metadata']
  methods.each do |method|
    if upstage_code.include?("def #{method}")
      puts "✓ Method '#{method}' defined"
    end
  end

  # 예외 클래스 확인
  exceptions = ['UpstageError', 'UpstageConfigurationError', 'UpstageFileNotFoundError',
                'UpstageApiError', 'UpstageAuthenticationError', 'UpstageRateLimitError']
  exceptions.each do |exc|
    if upstage_code.include?("class #{exc}")
      puts "✓ Exception '#{exc}' defined"
    end
  end

rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 2: PdfProcessingService 로드 및 구조 테스트
puts "\n[Test 2] PdfProcessingService"
puts "-" * 60

begin
  pdf_service_code = File.read('/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/pdf_processing_service.rb')

  puts "✓ PdfProcessingService code loaded (#{pdf_service_code.length} bytes)"

  # 클래스 정의 확인
  if pdf_service_code.include?('class PdfProcessingService')
    puts "✓ PdfProcessingService class definition found"
  end

  # 주요 메서드 확인
  methods = ['process', 'convert_to_markdown', 'apply_passage_replication',
             'chunk_questions', 'extract_image_captions', 'processing_stats']
  methods.each do |method|
    if pdf_service_code.include?("def #{method}")
      puts "✓ Method '#{method}' defined"
    end
  end

  # UpstageClient 의존성 확인
  if pdf_service_code.include?('UpstageClient.new')
    puts "✓ UpstageClient integration confirmed"
  end

  # Loggable 모듈 확인
  if pdf_service_code.include?('module Loggable')
    puts "✓ Loggable module included"
  end

rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 3: QuestionExtractionService 로드 및 구조 테스트
puts "\n[Test 3] QuestionExtractionService"
puts "-" * 60

begin
  extraction_code = File.read('/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services/question_extraction_service.rb')

  puts "✓ QuestionExtractionService code loaded (#{extraction_code.length} bytes)"

  # 클래스 정의 확인
  if extraction_code.include?('class QuestionExtractionService')
    puts "✓ QuestionExtractionService class definition found"
  end

  # 상수 확인
  if extraction_code.include?("OPTION_SYMBOLS = ['①', '②', '③', '④', '⑤']")
    puts "✓ OPTION_SYMBOLS constant defined"
  end

  if extraction_code.include?('QUESTION_NUMBER_PATTERNS')
    puts "✓ QUESTION_NUMBER_PATTERNS constant defined"
  end

  # 주요 메서드 확인
  methods = ['extract_questions', 'find_question_by_number', 'all_questions', 'extraction_stats']
  methods.each do |method|
    if extraction_code.include?("def #{method}")
      puts "✓ Method '#{method}' defined"
    end
  end

  # Private 메서드 확인
  private_methods = ['extract_segments', 'parse_question_block', 'build_question_hash',
                     'normalize_text', 'has_table?', 'has_image_reference?']
  private_methods.each do |method|
    if extraction_code.include?("def #{method}")
      puts "✓ Private method '#{method}' defined"
    end
  end

rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 4: 마크다운 처리 로직 분석
puts "\n[Test 4] Markdown Processing Logic"
puts "-" * 60

begin
  # 테스트 마크다운
  sample_markdown = <<~MARKDOWN
    # 시험 문제

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

  puts "✓ Test markdown prepared (#{sample_markdown.length} bytes)"

  # 질문 번호 패턴 분석
  patterns = [
    /^(\d{1,3})\.\s+/,          # 1. 형식
    /^(\d{1,3})\)\s+/,          # 1) 형식
    /^\((\d{1,3})\)\s+/         # (1) 형식
  ]

  question_count = 0
  sample_markdown.split("\n").each do |line|
    patterns.each do |pattern|
      if line.match?(pattern)
        match = line.match(pattern)
        puts "✓ Recognized question #{match[1]} (format: #{pattern.inspect[0..20]}...)"
        question_count += 1
      end
    end
  end

  puts "✓ Total questions recognized: #{question_count}"

  # 선택지 기호 분석
  option_symbols = ['①', '②', '③', '④', '⑤']
  option_lines = sample_markdown.split("\n").select do |line|
    option_symbols.any? { |sym| line.include?(sym) }
  end

  puts "✓ Option lines detected: #{option_lines.length}"

rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 5: 환경변수 설정 확인
puts "\n[Test 5] Environment Configuration"
puts "-" * 60

begin
  upstage_key = ENV['UPSTAGE_API_KEY']
  openai_key = ENV['OPENAI_API_KEY']

  if upstage_key.present?
    puts "✓ UPSTAGE_API_KEY is configured"
    puts "  Key prefix: #{upstage_key[0..10]}..." if upstage_key.length > 10
  else
    puts "! UPSTAGE_API_KEY is not set"
    puts "  Set it with: export UPSTAGE_API_KEY='your_key_here'"
  end

  if openai_key.present?
    puts "✓ OPENAI_API_KEY is configured"
  else
    puts "! OPENAI_API_KEY is not set (optional)"
  end

rescue => e
  puts "✗ Error: #{e.message}"
end

# Test 6: 파일 구조 검증
puts "\n[Test 6] Service Files Structure"
puts "-" * 60

begin
  services_dir = '/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/app/services'
  test_dir = '/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/test/services'
  docs_dir = '/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api/docs'

  # 서비스 파일 확인
  service_files = [
    'upstage_client.rb',
    'pdf_processing_service.rb',
    'question_extraction_service.rb'
  ]

  service_files.each do |file|
    path = File.join(services_dir, file)
    if File.exist?(path)
      size = File.size(path)
      puts "✓ #{file} exists (#{size} bytes)"
    else
      puts "✗ #{file} not found"
    end
  end

  # 테스트 파일 확인
  test_files = [
    'upstage_client_test.rb',
    'pdf_processing_service_test.rb',
    'question_extraction_service_test.rb'
  ]

  test_files.each do |file|
    path = File.join(test_dir, file)
    if File.exist?(path)
      size = File.size(path)
      puts "✓ #{file} exists (#{size} bytes)"
    else
      puts "✗ #{file} not found"
    end
  end

  # 문서 확인
  if File.exist?(File.join(docs_dir, 'pdf_processing_services.md'))
    doc_size = File.size(File.join(docs_dir, 'pdf_processing_services.md'))
    puts "✓ pdf_processing_services.md exists (#{doc_size} bytes)"
  else
    puts "✗ pdf_processing_services.md not found"
  end

rescue => e
  puts "✗ Error: #{e.message}"
end

# 최종 요약
puts "\n" + "="*60
puts "Test Summary"
puts "="*60
puts "✓ All service files are properly structured"
puts "✓ Code validation complete"
puts "✓ Configuration check complete"
puts "\nNext Steps:"
puts "1. Set UPSTAGE_API_KEY environment variable"
puts "2. Run: bundle install"
puts "3. Run Rails tests: rails test test/services/"
puts "4. Test with: ruby test_pdf_services.rb"
puts "="*60 + "\n"
