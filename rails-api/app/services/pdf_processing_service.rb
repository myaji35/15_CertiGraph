# PDF 처리 서비스
# Upstage API를 사용하여 PDF를 마크다운으로 변환하고 질문을 추출

class PdfProcessingService
  include Loggable

  attr_reader :file_path, :markdown_content, :metadata

  # @param file_path [String] PDF 파일 경로
  def initialize(file_path)
    @file_path = file_path
    @upstage_client = UpstageClient.new
    @markdown_content = nil
    @metadata = {}
    @extraction_service = nil
  end

  # 전체 처리 파이프라인
  # @return [Hash] { questions: [], metadata: {}, markdown: '' }
  def process
    log_info("Starting PDF processing: #{File.basename(@file_path)}")

    # 1. PDF를 마크다운으로 변환
    convert_to_markdown
    log_info("PDF converted to markdown (#{@markdown_content.length} characters)")

    # 2. 지문 복제 전략 적용
    apply_passage_replication

    # 3. 질문 및 보기 추출
    extraction_service = QuestionExtractionService.new(@markdown_content)
    questions = extraction_service.extract_questions
    log_info("Extracted #{questions.length} questions")

    # 4. 결과 반환
    {
      success: true,
      questions: questions,
      metadata: @metadata,
      markdown: @markdown_content,
      total_questions: questions.length,
      chunks: chunk_questions(questions, chunk_size: 10).length
    }
  rescue => e
    log_error("PDF processing failed: #{e.message}\n#{e.backtrace.join("\n")}")
    {
      success: false,
      error: e.message,
      error_class: e.class.name
    }
  end

  # PDF를 마크다운으로 변환
  def convert_to_markdown
    log_info("Converting PDF to markdown using Upstage API")

    response = @upstage_client.parse_document(@file_path)

    if response.is_a?(Hash) && response['markdown'].present?
      @markdown_content = response['markdown']
      @metadata = response.except('markdown')
      log_info("Successfully converted PDF to markdown")
      @markdown_content
    else
      raise "Invalid response from Upstage API"
    end
  rescue UpstageError => e
    log_error("Upstage API error: #{e.message}")
    raise
  end

  # 지문 복제 전략 적용
  # 동일 지문을 참조하는 여러 문제들을 식별하고 처리
  def apply_passage_replication
    return unless @markdown_content.present?

    log_info("Applying passage replication strategy")

    # 마크다운에서 지문 패턴 식별
    # 예: "다음을 읽고...", "다음 글을 읽고..."
    @markdown_content = identify_and_mark_passages(@markdown_content)
  end

  # 문제들을 청킹으로 분할
  # @param questions [Array<Hash>] 질문 배열
  # @param chunk_size [Integer] 청크 크기
  # @return [Array<Array<Hash>>] 청킹된 질문 배열
  def chunk_questions(questions, chunk_size: 10)
    questions.each_slice(chunk_size).to_a
  end

  # 마크다운에서 이미지 캡션 추출 및 생성
  # @return [Hash] { image_path => caption }
  def extract_image_captions
    captions = {}

    # Upstage API가 이미지 캡션을 제공하는 경우
    if @metadata['images'].is_a?(Array)
      @metadata['images'].each do |image_data|
        image_path = image_data['path']
        # 기존 캡션이 있으면 사용, 없으면 빈 문자열
        captions[image_path] = image_data['caption'] || ''
      end
    end

    captions
  end

  # 처리 통계 반환
  # @return [Hash] 처리 통계
  def processing_stats
    {
      file_path: @file_path,
      markdown_length: @markdown_content&.length || 0,
      has_metadata: @metadata.present?,
      metadata_keys: @metadata.keys
    }
  end

  # 마크다운 유효성 검증
  # @return [Boolean] 유효한 마크다운인지 여부
  def valid_markdown?
    @markdown_content.present? && @markdown_content.is_a?(String)
  end

  private

  def identify_and_mark_passages(content)
    # 지문 시작 패턴: "다음을 읽고", "아래 글을", "다음 글을" 등
    passage_start_pattern = /(?:다음|아래)\s*(?:을|을\s)?\s*읽고|다음\s+글|다음\s+문항을\s+읽고/

    lines = content.split("\n")
    processed_lines = []
    in_passage = false
    passage_counter = 0

    lines.each do |line|
      if line.match?(passage_start_pattern)
        in_passage = true
        passage_counter += 1
        # 마크다운 주석으로 지문 표시
        processed_lines << "\n<!-- PASSAGE #{passage_counter} START -->"
        processed_lines << line
      elsif in_passage && line.match?(/^#{Regexp.escape('1.')}\s|^#{Regexp.escape('①')}\s|^#{Regexp.escape('(1)')}\s/)
        # 문제 번호 패턴이 감지되면 지문 종료
        processed_lines << "<!-- PASSAGE #{passage_counter} END -->\n"
        in_passage = false
        processed_lines << line
      else
        processed_lines << line
      end
    end

    # 마지막 지문이 닫히지 않았으면 닫기
    if in_passage && passage_counter > 0
      processed_lines << "\n<!-- PASSAGE #{passage_counter} END -->"
    end

    processed_lines.join("\n")
  end

  # 로깅 모듈
  module Loggable
    def log_info(message)
      Rails.logger.info("[PdfProcessingService] #{message}")
    end

    def log_error(message)
      Rails.logger.error("[PdfProcessingService] #{message}")
    end

    def log_warn(message)
      Rails.logger.warn("[PdfProcessingService] #{message}")
    end
  end
end
