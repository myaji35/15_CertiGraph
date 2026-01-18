# frozen_string_literal: true

require 'httparty'

class UpstageOcrService
  include HTTParty
  base_uri 'https://api.upstage.ai/v1/document-ai'

  def initialize
    @api_key = ENV['UPSTAGE_API_KEY']
    raise 'UPSTAGE_API_KEY is not set' if @api_key.blank?
  end

  # Extract text from PDF
  def extract_text(pdf_path)
    response = self.class.post(
      '/document-parse',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'multipart/form-data'
      },
      body: {
        document: File.new(pdf_path)
      }
    )

    handle_response(response)
  end

  # Extract text with OCR (for scanned PDFs)
  def extract_with_ocr(pdf_path)
    response = self.class.post(
      '/ocr',
      headers: {
        'Authorization' => "Bearer #{@api_key}",
        'Content-Type' => 'multipart/form-data'
      },
      body: {
        document: File.new(pdf_path),
        ocr: true
      }
    )

    handle_response(response)
  end

  private

  def handle_response(response)
    if response.success?
      parse_result(response.parsed_response)
    else
      Rails.logger.error "Upstage OCR failed: #{response.code} - #{response.message}"
      raise "OCR 처리 실패: #{response.message}"
    end
  end

  def parse_result(data)
    {
      text: data['content']&.dig('text') || '',
      pages: data['content']&.dig('pages') || [],
      metadata: {
        page_count: data['content']&.dig('pages')&.length || 0,
        language: data['content']&.dig('language'),
        confidence: data['content']&.dig('confidence')
      }
    }
  end
end
