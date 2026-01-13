#!/usr/bin/env ruby
# 간단한 PDF 파서 테스트 (Rails console에서 실행)

# Rails console에서 실행:
# rails console
# load 'test_simple_parser.rb'

def test_pdf_parser
  puts "PDF 파서 테스트 시작..."
  puts "=" * 50

  # 테스트용 텍스트 파일 사용 (PDF 대신)
  test_file = Rails.root.join('test/fixtures/sample_questions.txt')

  begin
    # PdfParserService는 pdf-reader를 사용하므로
    # 실제 PDF가 아닌 텍스트 파일로는 작동하지 않을 수 있음
    # 대신 직접 텍스트 파싱 로직 테스트

    text = File.read(test_file)

    # 직접 파싱 로직 구현 (PdfParserService의 parse_questions 메서드 일부)
    questions = []

    # 문제 번호로 분리 (1., 2., 3., ... )
    question_pattern = /(\d+)\.\s+(.+?)(?=\n(?:\d+\.|정답:|다음 글을 읽고|$))/m
    matches = text.scan(question_pattern)

    matches.each do |match|
      question_number = match[0].to_i
      content = match[1]

      # 선택지 추출
      option_pattern = /([①②③④⑤])\s*(.+?)(?=[①②③④⑤]|\n정답:|\n\d+\.|\z)/m
      options = content.scan(option_pattern)

      # 문제 텍스트 추출 (선택지 전까지)
      question_text = content.split(/[①②③④⑤]/).first.strip

      # 정답 추출
      answer_match = text.match(/문제.*?#{question_number}.*?정답:\s*([①②③④⑤\d])/m)
      answer = answer_match ? answer_match[1] : nil

      questions << {
        question_number: question_number,
        question_text: question_text,
        options: options.map { |o| { symbol: o[0], text: o[1].strip } },
        correct_answer: answer
      }
    end

    puts "\n📊 파싱 결과:"
    puts "총 문제 수: #{questions.length}개"
    puts "-" * 50

    questions.each do |q|
      puts "\n문제 #{q[:question_number]}:"
      puts "내용: #{q[:question_text][0..80]}..."
      puts "선택지 수: #{q[:options].length}"
      puts "정답: #{q[:correct_answer]}"
    end

    puts "\n✅ 파싱 테스트 완료!"

  rescue => e
    puts "\n❌ 오류 발생: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  end
end

# Rails console이 아닌 경우 직접 실행
if defined?(Rails)
  test_pdf_parser
else
  puts "Rails console에서 실행해주세요:"
  puts "rails console"
  puts "load 'test_simple_parser.rb'"
end