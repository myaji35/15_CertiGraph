# Image Extraction Service
# PDF에서 이미지를 추출하고 GPT-4o를 사용하여 캡션 생성

require 'mini_magick'

class ImageExtractionService
  attr_reader :pdf_path, :output_dir, :extracted_images

  def initialize(pdf_path, output_dir: nil)
    @pdf_path = pdf_path
    @output_dir = output_dir || Rails.root.join('tmp', 'extracted_images')
    @extracted_images = []
    @openai_client = OpenAIClient.new

    ensure_output_directory
  end

  # 전체 이미지 추출 및 캡션 생성 파이프라인
  # @return [Array<Hash>] 추출된 이미지 정보
  def extract_and_caption
    Rails.logger.info("[ImageExtraction] Starting extraction from: #{File.basename(@pdf_path)}")

    # 1. PDF에서 이미지 추출
    extract_images_from_pdf

    # 2. 각 이미지에 대해 GPT-4o로 캡션 생성
    generate_captions_for_images

    # 3. 결과 반환
    {
      success: true,
      total_images: @extracted_images.length,
      images: @extracted_images
    }
  rescue StandardError => e
    Rails.logger.error("[ImageExtraction] Failed: #{e.message}")
    {
      success: false,
      error: e.message,
      error_class: e.class.name
    }
  end

  # PDF에서 이미지 추출
  def extract_images_from_pdf
    # ImageMagick을 사용하여 PDF 페이지를 이미지로 변환
    begin
      pdf = MiniMagick::Image.open(@pdf_path)
      pages = pdf.pages

      Rails.logger.info("[ImageExtraction] Found #{pages.length} pages")

      pages.each_with_index do |page, index|
        output_path = File.join(@output_dir, "page_#{index + 1}.png")

        # 페이지를 PNG로 변환
        page.format 'png'
        page.write output_path

        @extracted_images << {
          page_number: index + 1,
          path: output_path,
          filename: File.basename(output_path),
          extracted_at: Time.current
        }
      end

      Rails.logger.info("[ImageExtraction] Extracted #{@extracted_images.length} images")
    rescue MiniMagick::Error => e
      Rails.logger.error("[ImageExtraction] ImageMagick error: #{e.message}")
      raise "Image extraction failed: #{e.message}"
    end
  end

  # 추출된 이미지에 대해 GPT-4o로 캡션 생성
  def generate_captions_for_images
    @extracted_images.each do |image_data|
      begin
        caption = generate_caption_with_gpt4o(image_data[:path])
        image_data[:caption] = caption
        image_data[:caption_generated_at] = Time.current

        Rails.logger.info("[ImageExtraction] Generated caption for #{image_data[:filename]}")
      rescue StandardError => e
        Rails.logger.warn("[ImageExtraction] Failed to generate caption: #{e.message}")
        image_data[:caption] = ''
        image_data[:caption_error] = e.message
      end
    end
  end

  # GPT-4o를 사용한 이미지 캡션 생성
  # @param image_path [String] 이미지 파일 경로
  # @return [String] 생성된 캡션
  def generate_caption_with_gpt4o(image_path)
    # 이미지를 Base64로 인코딩
    base64_image = encode_image_to_base64(image_path)

    # GPT-4o Vision API 호출
    response = @openai_client.chat_with_vision(
      model: 'gpt-4o',
      messages: [
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: '이 이미지는 자격증 시험 문제의 일부입니다. 이미지의 내용을 자세히 설명해주세요. 표, 그래프, 다이어그램이 있다면 구체적으로 설명하고, 문제 풀이에 필요한 정보를 모두 포함해주세요.'
            },
            {
              type: 'image_url',
              image_url: {
                url: "data:image/png;base64,#{base64_image}"
              }
            }
          ]
        }
      ],
      max_tokens: 500
    )

    extract_caption_from_response(response)
  rescue StandardError => e
    Rails.logger.error("[ImageExtraction] Caption generation failed: #{e.message}")
    "이미지 분석 실패: #{e.message}"
  end

  # 이미지 크롭 및 최적화
  # @param image_path [String] 이미지 경로
  # @param crop_area [Hash] { x, y, width, height }
  # @return [String] 크롭된 이미지 경로
  def crop_image(image_path, crop_area)
    image = MiniMagick::Image.open(image_path)

    cropped_path = image_path.sub('.png', '_cropped.png')

    image.crop "#{crop_area[:width]}x#{crop_area[:height]}+#{crop_area[:x]}+#{crop_area[:y]}"
    image.write cropped_path

    cropped_path
  rescue MiniMagick::Error => e
    Rails.logger.error("[ImageExtraction] Crop failed: #{e.message}")
    image_path # 실패 시 원본 반환
  end

  # 이미지 품질 최적화
  # @param image_path [String] 이미지 경로
  # @param quality [Integer] 품질 (1-100)
  def optimize_image(image_path, quality: 85)
    image = MiniMagick::Image.open(image_path)

    image.quality quality
    image.strip # 메타데이터 제거
    image.write image_path

    Rails.logger.info("[ImageExtraction] Optimized: #{image_path}")
  rescue MiniMagick::Error => e
    Rails.logger.error("[ImageExtraction] Optimization failed: #{e.message}")
  end

  # 추출된 이미지 정리
  def cleanup
    return unless Dir.exist?(@output_dir)

    FileUtils.rm_rf(@output_dir)
    Rails.logger.info("[ImageExtraction] Cleaned up: #{@output_dir}")
  rescue StandardError => e
    Rails.logger.warn("[ImageExtraction] Cleanup failed: #{e.message}")
  end

  private

  def ensure_output_directory
    FileUtils.mkdir_p(@output_dir) unless Dir.exist?(@output_dir)
  end

  def encode_image_to_base64(image_path)
    Base64.strict_encode64(File.read(image_path))
  end

  def extract_caption_from_response(response)
    content = response.dig('choices', 0, 'message', 'content')
    content.presence || '이미지 설명 생성 실패'
  end
end
