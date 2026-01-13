#!/usr/bin/env ruby
# PDF 파서 테스트 스크립트

require 'tempfile'
require 'prawn'  # PDF 생성을 위한 gem (설치 필요할 수 있음)

# 테스트용 PDF 생성 함수
def create_test_pdf
  Tempfile.new(['test_questions', '.pdf']).tap do |file|
    Prawn::Document.generate(file.path, page_size: 'A4') do |pdf|
      pdf.font_families.update(
        "NanumGothic" => {
          normal: "/System/Library/Fonts/Helvetica.ttc"  # 시스템 폰트 사용
        }
      ) rescue nil  # 한글 폰트가 없으면 기본 폰트 사용

      pdf.text "2025년 사회복지사 1급 기출문제", size: 18, style: :bold
      pdf.move_down 20

      pdf.text "1. 다음 중 사회복지정책의 기본 원칙에 해당하지 않는 것은?"
      pdf.move_down 10
      pdf.text "① 보편성의 원칙"
      pdf.text "② 형평성의 원칙"
      pdf.text "③ 효율성의 원칙"
      pdf.text "④ 수익자 부담의 원칙"
      pdf.text "⑤ 적절성의 원칙"
      pdf.move_down 20

      pdf.text "2. 사회복지실천의 통합적 접근방법(generalist approach)에 대한 설명으로 옳은 것은?"
      pdf.move_down 10
      pdf.text "① 특정 이론에 기반한 접근방법이다"
      pdf.text "② 개인, 가족, 집단, 지역사회 등 다양한 체계수준에 개입한다"
      pdf.text "③ 의료사회복지 분야에만 적용된다"
      pdf.text "④ 미시적 개입에 중점을 둔다"
      pdf.text "⑤ 거시적 개입에 중점을 둔다"
      pdf.move_down 20

      pdf.text "다음 글을 읽고 3~4번 문제에 답하시오."
      pdf.move_down 10
      pdf.text "사회복지사 A씨는 지역아동센터에서 근무하며 저소득층 아동들을 대상으로 방과후 프로그램을 운영하고 있다."
      pdf.move_down 20

      pdf.text "3. 위 사례에서 사회복지사 A씨가 수행한 역할로 가장 적절한 것은?"
      pdf.move_down 10
      pdf.text "① 행정가"
      pdf.text "② 중재자"
      pdf.text "③ 연구자"
      pdf.text "④ 교육자"
      pdf.text "⑤ 옹호자"
    end

    file
  end
end

# PdfParserService 직접 테스트 (Rails 환경 밖에서)
if __FILE__ == $0
  # Rails 환경 로드
  require_relative 'config/environment'

  puts "PDF 파서 테스트 시작..."
  puts "=" * 50

  # 테스트용 PDF 생성 시도
  begin
    require 'prawn'
    pdf_file = create_test_pdf
    pdf_path = pdf_file.path
    puts "✅ 테스트 PDF 생성 완료: #{pdf_path}"
  rescue LoadError
    # Prawn이 없으면 텍스트 파일을 사용
    pdf_path = Rails.root.join('test/fixtures/sample_questions.txt')
    puts "⚠️  Prawn gem이 없어 텍스트 파일 사용: #{pdf_path}"
  end

  # PdfParserService 테스트
  begin
    parser = PdfParserService.new(pdf_path.to_s)
    questions = parser.extract_questions

    puts "\n📊 파싱 결과:"
    puts "총 문제 수: #{questions.length}개"
    puts "-" * 50

    questions.each_with_index do |q, i|
      puts "\n문제 #{i + 1}:"
      puts "번호: #{q[:question_number]}"
      puts "내용: #{q[:question_text][0..100]}..." if q[:question_text]
      puts "선택지 수: #{q[:options].length}" if q[:options]
      puts "정답: #{q[:correct_answer]}" if q[:correct_answer]
      puts "지문: #{q[:passage] ? '있음' : '없음'}"
    end

    # 지문 복제 테스트
    puts "\n🔄 지문 복제 처리 테스트..."
    processed_questions = parser.process_passage_replication(questions)

    passage_questions = processed_questions.select { |q| q[:passage].present? }
    puts "지문이 있는 문제: #{passage_questions.length}개"

    # 청킹 테스트
    puts "\n📦 청킹 테스트..."
    chunks = parser.chunk_questions(processed_questions, 2)
    puts "총 청크 수: #{chunks.length}개"
    puts "청크당 문제 수: #{chunks.map(&:length).join(', ')}"

    puts "\n✅ PDF 파서 테스트 완료!"

  rescue => e
    puts "\n❌ 오류 발생: #{e.message}"
    puts e.backtrace.first(5).join("\n")
  ensure
    # 임시 파일 삭제
    pdf_file&.close
    pdf_file&.unlink rescue nil
  end
end