# 질문 추출 서비스
# 마크다운 형식의 문서에서 질문, 선택지, 답안을 추출

class QuestionExtractionService
  OPTION_SYMBOLS = ['①', '②', '③', '④', '⑤'].freeze
  QUESTION_NUMBER_PATTERNS = [
    /^(\d{1,3})\.\s+/,          # 1. 형식
    /^(\d{1,3})\)\s+/,          # 1) 형식
    /^\((\d{1,3})\)\s+/         # (1) 형식
  ].freeze

  attr_reader :markdown_content, :questions

  # @param markdown_content [String] 마크다운 형식의 문서
  def initialize(markdown_content)
    @markdown_content = markdown_content
    @questions = []
    @current_passage = nil
  end

  # 마크다운에서 모든 질문 추출
  # @return [Array<Hash>] 추출된 질문 배열
  def extract_questions
    return [] if @markdown_content.blank?

    # 1단계: 지문과 질문 분리
    segments = extract_segments

    # 2단계: 각 세그먼트에서 질문 추출
    questions = []
    current_passage = nil

    segments.each do |segment|
      if segment[:type] == :passage
        current_passage = segment[:content]
      elsif segment[:type] == :question_block
        parsed_questions = parse_question_block(segment[:content], current_passage)
        questions.concat(parsed_questions)
      end
    end

    @questions = questions
  end

  # 특정 질문 번호의 질문 조회
  # @param question_number [Integer] 질문 번호
  # @return [Hash, nil] 해당 질문 또는 nil
  def find_question_by_number(question_number)
    @questions.find { |q| q[:question_number] == question_number }
  end

  # 모든 추출된 질문 반환
  # @return [Array<Hash>]
  def all_questions
    @questions
  end

  # 추출 통계
  # @return [Hash]
  def extraction_stats
    {
      total_questions: @questions.length,
      questions_with_passages: @questions.count { |q| q[:passage].present? },
      questions_without_passages: @questions.count { |q| q[:passage].blank? },
      average_options: @questions.map { |q| q[:options]&.length || 0 }.sum.to_f / [@questions.length, 1].max
    }
  end

  private

  # 마크다운을 지문과 질문 블록으로 분리
  # @return [Array<Hash>] { type: :passage or :question_block, content: String }
  def extract_segments
    segments = []
    lines = @markdown_content.split("\n")

    current_block = []
    current_type = nil
    current_passage = nil
    passage_markers = Hash.new { |h, k| h[k] = [] }

    lines.each_with_index do |line, index|
      # 지문 시작 마커 감지
      if line.include?('<!-- PASSAGE') && line.include?('START -->')
        passage_num = line.match(/PASSAGE (\d+)/)[1].to_i
        passage_markers[passage_num] << { start: index, end: nil }

        if current_block.present?
          segments << { type: current_type, content: current_block.join("\n") }
          current_block = []
        end
        current_type = :passage
      # 지문 종료 마커 감지
      elsif line.include?('<!-- PASSAGE') && line.include?('END -->')
        if current_type == :passage && current_block.present?
          segments << { type: :passage, content: current_block.join("\n") }
          current_block = []
          current_type = nil
        end
      # 질문 번호 패턴 감지
      elsif question_number_match?(line)
        if current_type != :question_block && current_block.present?
          segments << { type: current_type || :passage, content: current_block.join("\n") }
          current_block = []
        end
        current_type = :question_block
        current_block << line
      elsif current_type.present?
        current_block << line
      elsif line.strip.present?
        if current_type != :passage
          current_block << line
        else
          current_block << line
        end
      end
    end

    # 마지막 블록 처리
    if current_block.present?
      segments << { type: current_type || :question_block, content: current_block.join("\n") }
    end

    segments.compact
  end

  # 질문 블록 파싱
  # @param block_content [String] 질문 블록 텍스트
  # @param passage [String] 관련 지문 (선택)
  # @return [Array<Hash>] 추출된 질문 배열
  def parse_question_block(block_content, passage = nil)
    questions = []
    lines = block_content.split("\n")

    current_question = nil
    current_question_text = []
    current_options = []

    lines.each do |line|
      next if line.blank?

      # 질문 번호 감지
      if match = extract_question_number(line)
        # 이전 질문 저장
        if current_question.present?
          question_data = build_question_hash(
            current_question,
            current_question_text.join("\n"),
            current_options,
            passage
          )
          questions << question_data if question_data
        end

        # 새로운 질문 시작
        current_question = match[:number]
        current_question_text = [match[:remaining_text]].compact
        current_options = []
      elsif option_symbol_match?(line)
        # 선택지 파싱
        option = parse_option(line)
        current_options << option if option
      elsif current_question.present?
        # 질문 텍스트 계속
        current_question_text << line unless option_symbol_match?(line)
      end
    end

    # 마지막 질문 저장
    if current_question.present?
      question_data = build_question_hash(
        current_question,
        current_question_text.join("\n"),
        current_options,
        passage
      )
      questions << question_data if question_data
    end

    questions
  end

  # 질문 해시 빌드
  # @return [Hash]
  def build_question_hash(question_number, question_text, options, passage)
    return nil if question_text.blank? || options.length < 2

    clean_text = normalize_text(question_text)
    options_hash = format_options(options)

    {
      question_number: question_number,
      question_text: clean_text,
      options: options_hash,
      answer: nil,  # 답안은 별도 처리 필요
      explanation: nil,
      passage: passage,
      option_count: options.length,
      has_table: has_table?(clean_text),
      has_image: has_image_reference?(clean_text)
    }
  end

  # 질문 번호 추출
  # @return [Hash] { number: Integer, remaining_text: String } or nil
  def extract_question_number(line)
    QUESTION_NUMBER_PATTERNS.each do |pattern|
      if match = line.match(pattern)
        number = match[1].to_i
        remaining_text = line.sub(pattern, '').strip
        return {
          number: number,
          remaining_text: remaining_text.present? ? remaining_text : nil
        }
      end
    end
    nil
  end

  # 질문 번호 패턴 확인
  # @return [Boolean]
  def question_number_match?(line)
    QUESTION_NUMBER_PATTERNS.any? { |pattern| line.match?(pattern) }
  end

  # 선택지 기호 매칭
  # @return [Boolean]
  def option_symbol_match?(line)
    OPTION_SYMBOLS.any? { |symbol| line.include?(symbol) }
  end

  # 선택지 파싱
  # @param line [String] 선택지 라인
  # @return [Hash] { symbol: String, text: String, number: Integer }
  def parse_option(line)
    OPTION_SYMBOLS.each_with_index do |symbol, index|
      if line.include?(symbol)
        option_text = line.sub(symbol, '').strip
        return {
          symbol: symbol,
          text: normalize_text(option_text),
          number: index + 1
        }
      end
    end
    nil
  end

  # 선택지를 해시 형식으로 변환
  # @param options [Array<Hash>]
  # @return [Hash] { '①' => '텍스트', '②' => '텍스트', ... }
  def format_options(options)
    formatted = {}
    options.each do |option|
      formatted[option[:symbol]] = option[:text]
    end
    formatted
  end

  # 텍스트 정규화
  # @param text [String] 정규화할 텍스트
  # @return [String]
  def normalize_text(text)
    return '' if text.blank?

    # 줄바꿈을 공백으로 변환
    text = text.gsub(/\n+/, ' ')

    # 과도한 공백 제거
    text = text.gsub(/\s+/, ' ')

    # 앞뒤 공백 제거
    text.strip
  end

  # 테이블 포함 여부 확인
  # @param text [String]
  # @return [Boolean]
  def has_table?(text)
    table_indicators = ['|', '(ㄱ)', '(ㄴ)', '(ㄷ)', '(ㄹ)', 'ㄱ:', 'ㄴ:', 'ㄷ:', 'ㄹ:']
    table_indicators.any? { |indicator| text.include?(indicator) }
  end

  # 이미지 참조 여부 확인
  # @param text [String]
  # @return [Boolean]
  def has_image_reference?(text)
    text.include?('![') || text.include?('[image') || text.include?('(http')
  end
end
