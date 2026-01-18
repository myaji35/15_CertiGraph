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
  def extract_text_from_pdf(pdf_path)
    Rails.logger.info "Starting Upstage OCR for: #{pdf_path}"
    
    response = self.class.post(
      '/document-parse',
      headers: {
        'Authorization' => "Bearer #{@api_key}"
      },
      body: {
        document: File.new(pdf_path, 'rb')
      }
    )

    handle_response(response)
  end

  private

  def handle_response(response)
    if response.success?
      parse_result(response.parsed_response)
    else
      error_msg = "Upstage OCR failed: #{response.code} - #{response.message}"
      Rails.logger.error error_msg
      raise StandardError, error_msg
    end
  end

  def parse_result(data)
    content = data.dig('content') || {}
    
    {
      text: extract_text_content(content),
      pages: content['pages'] || [],
      metadata: {
        page_count: (content['pages'] || []).length,
        language: content['language'],
        confidence: content['confidence'],
        processing_time: data['processing_time']
      }
    }
  end

  def extract_text_content(content)
    if content['text'].present?
      content['text']
    elsif content['pages'].present?
      content['pages'].map { |page| page['text'] }.join("\n\n")
    else
      ''
    end
  end
end
