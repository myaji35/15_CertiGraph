# Upstage Document Parse API 클라이언트
# Upstage의 Document Parse API를 사용하여 PDF를 마크다운으로 변환

require 'httparty'
require 'base64'

class UpstageClient
  include HTTParty

  API_VERSION = 'v1'
  BASE_URI = 'https://api.upstage.ai'
  DOCUMENT_PARSE_ENDPOINT = '/v1/document-parse'

  # API 키 검증
  def self.configured?
    api_key.present?
  end

  def self.api_key
    ENV['UPSTAGE_API_KEY']
  end

  def initialize
    @api_key = self.class.api_key
    @headers = {
      'Authorization' => "Bearer #{@api_key}",
      'Content-Type' => 'application/octet-stream'
    }

    raise UpstageConfigurationError, 'UPSTAGE_API_KEY is not configured' unless @api_key.present?
  end

  # PDF 파일을 마크다운으로 변환
  # @param file_path [String] PDF 파일 경로 (로컬) 또는 파일 객체
  # @param output_format [String] 출력 포맷 ('markdown' 기본값)
  # @return [Hash] API 응답 { 'markdown' => '...' }
  def parse_document(file_path, output_format: 'markdown')
    validate_file(file_path)

    file_content = read_file(file_path)

    response = make_request(file_content)

    handle_response(response)
  end

  # 여러 파일을 배치 처리
  # @param file_paths [Array<String>] PDF 파일 경로 배열
  # @return [Array<Hash>] 파일별 처리 결과 배열
  def batch_parse(file_paths)
    results = []
    errors = []

    file_paths.each_with_index do |file_path, index|
      begin
        result = parse_document(file_path)
        results << {
          file_path: file_path,
          success: true,
          data: result,
          index: index
        }
      rescue => e
        Rails.logger.error("Failed to parse #{file_path}: #{e.message}")
        errors << {
          file_path: file_path,
          error: e.message,
          index: index
        }
        results << {
          file_path: file_path,
          success: false,
          error: e.message,
          index: index
        }
      end
    end

    {
      total: file_paths.length,
      successful: results.count { |r| r[:success] },
      failed: errors.length,
      results: results
    }
  end

  # OCR 결과 포함 상세 파싱
  # @param file_path [String] PDF 파일 경로
  # @return [Hash] { 'markdown' => '...', 'metadata' => {...} }
  def parse_with_metadata(file_path)
    validate_file(file_path)
    file_content = read_file(file_path)

    response = make_request(file_content, include_metadata: true)
    handle_response(response)
  end

  private

  def validate_file(file_path)
    case file_path
    when String
      unless File.exist?(file_path)
        raise UpstageFileNotFoundError, "File not found: #{file_path}"
      end
      unless file_path.downcase.end_with?('.pdf')
        raise UpstageInvalidFileError, "Only PDF files are supported"
      end
    when File
      true
    else
      raise UpstageInvalidFileError, "file_path must be a String or File object"
    end
  end

  def read_file(file_path)
    case file_path
    when String
      File.read(file_path)
    when File
      file_path.read
    when ActionDispatch::Http::UploadedFile
      file_path.read
    else
      raise UpstageInvalidFileError, "Cannot read file"
    end
  end

  def make_request(file_content, include_metadata: false)
    uri = URI.parse("#{BASE_URI}#{DOCUMENT_PARSE_ENDPOINT}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, @headers)
    request.body = file_content

    http.request(request)
  rescue StandardError => e
    Rails.logger.error("Upstage API request failed: #{e.message}")
    raise UpstageApiError, "API request failed: #{e.message}"
  end

  def handle_response(response)
    case response.code.to_i
    when 200, 201
      JSON.parse(response.body)
    when 400
      error_data = parse_error_response(response)
      raise UpstageValidationError, "Invalid request: #{error_data['message']}"
    when 401
      raise UpstageAuthenticationError, "Invalid API key or authentication failed"
    when 403
      raise UpstageAuthorizationError, "Access forbidden"
    when 429
      raise UpstageRateLimitError, "Rate limit exceeded. Please retry later."
    when 500..599
      raise UpstageServerError, "Upstage server error (#{response.code}): #{response.body}"
    else
      raise UpstageApiError, "Unexpected API response (#{response.code}): #{response.body}"
    end
  rescue JSON::ParserError
    raise UpstageApiError, "Failed to parse API response: #{response.body}"
  end

  def parse_error_response(response)
    JSON.parse(response.body)
  rescue JSON::ParserError
    { 'message' => response.body }
  end
end

# 커스텀 예외 클래스
class UpstageError < StandardError; end
class UpstageConfigurationError < UpstageError; end
class UpstageFileNotFoundError < UpstageError; end
class UpstageInvalidFileError < UpstageError; end
class UpstageApiError < UpstageError; end
class UpstageAuthenticationError < UpstageError; end
class UpstageAuthorizationError < UpstageError; end
class UpstageValidationError < UpstageError; end
class UpstageRateLimitError < UpstageError; end
class UpstageServerError < UpstageError; end
