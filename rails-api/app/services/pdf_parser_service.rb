# PDF 파싱 서비스 - Ruby pdf-reader gem을 사용한 로컬 파싱
require 'pdf-reader'

class PdfParserService
  def initialize(pdf_file_path)
    @pdf_file_path = pdf_file_path
  end

  def extract_questions
    Rails.logger.info "Extracting questions from PDF: #{@pdf_file_path}"
    questions = []

    begin
      PDF::Reader.open(@pdf_file_path) do |reader|
        full_text = ""

        # 모든 페이지의 텍스트 추출
        reader.pages.each do |page|
          full_text += page.text + "\n"
        end

        # 문제별로 분리
        questions = parse_questions(full_text)
      end

      Rails.logger.info "Successfully extracted #{questions.length} questions"
      questions
    rescue => e
      Rails.logger.error "Failed to extract questions: #{e.message}"
      raise e
    end
  end

  # 청킹 알고리즘 - 문제를 작은 단위로 분할
  def chunk_questions(questions, chunk_size = 10)
    questions.each_slice(chunk_size).to_a
  end

  # 지문 복제 - 동일 지문을 참조하는 문제들 처리
  def process_passage_replication(questions)
    current_passage = nil

    questions.each do |question|
      # 지문 시작 패턴 감지
      if question[:question_text].include?("다음을 읽고") ||
         question[:question_text].include?("아래 지문") ||
         question[:question_text].include?("다음 글")

        # 지문 추출
        passage_match = question[:question_text].match(/다음.*?(?=문제|물음|답하|$)/m)
        if passage_match
          current_passage = passage_match[0]
          question[:passage] = current_passage
        end
      elsif current_passage && question[:question_text].length < 100
        # 짧은 문제는 이전 지문을 참조할 가능성이 높음
        question[:passage] = current_passage
      else
        # 새로운 독립 문제
        current_passage = nil
      end
    end

    questions
  end

  private

  def parse_questions(text)
    questions = []

    # 문제 번호로 분리 (1., 2., 3., ... 100.)
    # 패턴: 줄 시작 + 숫자 + 마침표 + 공백
    question_pattern = /\n(\d{1,3})\.\s+/
    splits = text.split(question_pattern)

    # splits[0]은 헤더, 그 이후는 [번호, 내용, 번호, 내용, ...] 형태
    (1..splits.length-1).step(2).each do |i|
      if i + 1 < splits.length
        question_number = splits[i].to_i
        question_content = splits[i + 1]

        # 문제 파싱
        parsed = parse_single_question(question_number, question_content)
        questions << parsed if parsed
      end
    end

    questions
  end

  def parse_single_question(question_number, content)
    # 선택지 패턴: ①, ②, ③, ④, ⑤
    option_pattern = /([①②③④⑤])/

    # 선택지로 분리
    parts = content.split(option_pattern)

    return nil if parts.length < 3

    # 첫 부분이 문제 본문
    question_text = clean_text(parts[0])

    # 표 감지 및 처리
    if has_table_indicators?(question_text)
      question_text = process_table_content(question_text)
    end

    # 선택지 추출
    options = extract_options(parts)

    # 최소 2개 이상의 선택지가 있어야 유효
    return nil if options.length < 2

    # 정답은 임시로 설정 (실제로는 정답 페이지에서 추출해야 함)
    correct_answer = ((question_number - 1) % 5) + 1

    {
      question_number: question_number,
      question_text: question_text,
      options: options,
      correct_answer: correct_answer,
      explanation: "문제 #{question_number}번의 정답은 #{correct_answer}번입니다.",
      passage: nil
    }
  end

  def has_table_indicators?(text)
    strong_indicators = ['(ㄱ)', '(ㄴ)', '(ㄷ)', '(ㄹ)', '( ㄱ )', '( ㄴ )', '( ㄷ )', '( ㄹ )']
    weak_indicators = ['세 단계', '표', '나열', '들어갈', '순서대로', '내용을', '다음']

    strong_match = strong_indicators.any? { |indicator| text.include?(indicator) }
    weak_match_count = weak_indicators.count { |indicator| text.include?(indicator) }

    strong_match || weak_match_count >= 2
  end

  def process_table_content(text)
    # 표 구조를 마크다운 형식으로 변환
    lines = text.split("\n")
    processed_lines = []
    in_table = false
    table_rows = []

    lines.each do |line|
      # 표 시작 감지
      if line.include?('대상자') || line.include?('사회복지 주체') || line.include?('권리수준')
        in_table = true
        table_rows << line.strip.split(/\s{2,}/) # 2개 이상의 공백으로 분리
      elsif in_table && (line.include?('ㄱ') || line.include?('ㄴ') || line.include?('ㄷ'))
        table_rows << line.strip.split(/\s{2,}/)
      elsif in_table && line.strip.empty?
        # 빈 줄이면 표 종료
        in_table = false
        if table_rows.any?
          processed_lines << convert_to_markdown_table(table_rows)
          table_rows = []
        end
      elsif !in_table
        processed_lines << line
      end
    end

    # 남은 표 처리
    if table_rows.any?
      processed_lines << convert_to_markdown_table(table_rows)
    end

    processed_lines.join("\n")
  end

  def convert_to_markdown_table(rows)
    return "" if rows.empty?

    # 마크다운 테이블 생성
    lines = []
    rows.each_with_index do |row, index|
      lines << "| " + row.join(" | ") + " |"
      if index == 0 # 헤더 다음에 구분선 추가
        lines << "| " + Array.new(row.length, "---").join(" | ") + " |"
      end
    end

    "\n" + lines.join("\n") + "\n"
  end

  def extract_options(parts)
    options = []
    option_symbols = {'①' => 1, '②' => 2, '③' => 3, '④' => 4, '⑤' => 5}

    (1..parts.length-1).step(2).each do |i|
      if i + 1 < parts.length
        symbol = parts[i]
        if option_symbols.key?(symbol)
          option_number = option_symbols[symbol]
          option_text = clean_option_text(parts[i + 1])

          options << {
            number: option_number,
            text: option_text
          }
        end
      end
    end

    options
  end

  def clean_text(text)
    return "" unless text

    # 줄바꿈과 과도한 공백 정리
    text = text.strip
    text = text.gsub(/\s+/, ' ')

    # 페이지 정보 제거 (예: "2025년도")
    text = text.gsub(/2025년도.*?(?:\n|$)/, '')

    text.strip
  end

  def clean_option_text(text)
    return "" unless text

    lines = text.split("\n")
    cleaned_lines = []

    lines.each do |line|
      line = line.strip
      next if line.empty? || line.start_with?('2025년도')

      # ㄱ:, ㄴ:, ㄷ: 형식은 줄바꿈으로 유지
      if line.match?(/^[ㄱ-ㅎ]:/)
        cleaned_lines << "\n" + line
      else
        cleaned_lines << line
      end
    end

    result = cleaned_lines.join(' ').strip
    # 연속된 공백 제거
    result.gsub(/\s+/, ' ')
  end
end