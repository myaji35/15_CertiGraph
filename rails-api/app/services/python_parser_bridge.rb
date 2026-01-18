# Python Parser Bridge
# Executes Python PDF parser and returns structured data
class PythonParserBridge
  class PythonExecutionError < StandardError; end
  class ParserNotFoundError < StandardError; end

  PYTHON_PARSER_PATH = Rails.root.join('lib/python_parsers/exam_pdf_parser_v2.py')
  PYTHON_COMMAND = ENV.fetch('PYTHON_COMMAND', 'python3')

  attr_reader :pdf_path, :result

  def initialize(pdf_path)
    @pdf_path = pdf_path
    @result = nil

    # Validate parser exists
    unless File.exist?(PYTHON_PARSER_PATH)
      raise ParserNotFoundError, "Python parser not found at #{PYTHON_PARSER_PATH}"
    end

    # Validate PDF exists
    unless File.exist?(pdf_path)
      raise ArgumentError, "PDF file not found at #{pdf_path}"
    end
  end

  # Parse PDF and return structured data
  # @return [Hash] { success: Boolean, questions: Array, metadata: Hash }
  def parse
    Rails.logger.info("🐍 Python Parser: Starting PDF parsing")
    Rails.logger.info("📄 PDF: #{File.basename(@pdf_path)}")
    Rails.logger.info("📊 File size: #{File.size(@pdf_path)} bytes")

    start_time = Time.current

    begin
      # Execute Python parser
      json_output = execute_python_parser

      # Parse JSON result
      parsed_data = JSON.parse(json_output, symbolize_names: true)

      elapsed = (Time.current - start_time).round(2)
      Rails.logger.info("✅ Python Parser: Completed in #{elapsed}s")
      Rails.logger.info("📝 Questions extracted: #{parsed_data.dig(:questions)&.size || 0}")

      @result = {
        success: true,
        questions: transform_questions(parsed_data[:questions] || []),
        metadata: {
          exam_info: parsed_data[:exam_info] || {},
          processing_time: elapsed,
          parser_version: 'v2',
          total_questions: parsed_data.dig(:questions)&.size || 0
        }
      }
    rescue JSON::ParserError => e
      Rails.logger.error("❌ Python Parser: JSON parsing failed - #{e.message}")
      @result = {
        success: false,
        error: "JSON parsing failed: #{e.message}",
        questions: [],
        metadata: {}
      }
    rescue PythonExecutionError => e
      Rails.logger.error("❌ Python Parser: Execution failed - #{e.message}")
      @result = {
        success: false,
        error: e.message,
        questions: [],
        metadata: {}
      }
    rescue StandardError => e
      Rails.logger.error("❌ Python Parser: Unexpected error - #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @result = {
        success: false,
        error: "Unexpected error: #{e.message}",
        questions: [],
        metadata: {}
      }
    end

    @result
  end

  # Check if Python and dependencies are available
  # @return [Hash] { available: Boolean, python_version: String, pdfplumber: Boolean }
  def self.check_dependencies
    python_version = `#{PYTHON_COMMAND} --version 2>&1`.strip
    python_available = $?.success?

    pdfplumber_check = `#{PYTHON_COMMAND} -c "import pdfplumber; print(pdfplumber.__version__)" 2>&1`.strip
    pdfplumber_available = $?.success?

    {
      available: python_available && pdfplumber_available,
      python_version: python_available ? python_version : 'Not found',
      pdfplumber: pdfplumber_available ? pdfplumber_check : 'Not installed',
      parser_exists: File.exist?(PYTHON_PARSER_PATH)
    }
  end

  private

  def execute_python_parser
    require 'open3'
    require 'json'
    require 'tempfile'

    # Create temporary output file for JSON
    output_file = Tempfile.new(['parser_output', '.json'])

    begin
      # Prepare Python script that outputs JSON to stdout
      python_script = <<~PYTHON
        import sys
        import json
        sys.path.insert(0, '#{File.dirname(PYTHON_PARSER_PATH)}')
        from exam_pdf_parser_v2 import ExamPDFParser

        parser = ExamPDFParser('#{@pdf_path}')
        parser.extract_text()
        parser.identify_sections()
        questions = parser.parse_questions()

        # Convert to JSON
        json_str = parser.to_json()
        print(json_str)
      PYTHON

      # Execute Python with script via stdin
      stdout, stderr, status = Open3.capture3(
        PYTHON_COMMAND,
        '-c',
        python_script,
        stdin_data: ''
      )

      unless status.success?
        error_message = stderr.presence || stdout
        Rails.logger.error("Python stderr: #{stderr}") if stderr.present?
        Rails.logger.error("Python stdout: #{stdout}") if stdout.present?
        raise PythonExecutionError, "Python execution failed: #{error_message}"
      end

      if stdout.blank?
        raise PythonExecutionError, "Python parser returned no output"
      end

      stdout
    ensure
      output_file.close
      output_file.unlink
    end
  end

  def transform_questions(python_questions)
    return [] if python_questions.blank?

    python_questions.map do |q|
      # Transform choices array to options hash
      options_hash = {}
      if q[:choices].present?
        q[:choices].each do |choice|
          # choice: { number: 1, text: "답안 텍스트" }
          option_key = ["①", "②", "③", "④", "⑤"][choice[:number] - 1]
          options_hash[option_key] = choice[:text]
        end
      end

      # Transform passage items to text
      passage_text = nil
      if q[:passage].present? && q[:passage].any?
        passage_lines = q[:passage].map do |p|
          marker = p[:marker]
          text = p[:text]
          "#{marker} #{text}"
        end
        passage_text = passage_lines.join("\n")
      end

      # Build question hash in our format
      {
        question_number: q[:number],
        content: q[:question],
        options: options_hash,
        answer: nil,  # Python parser cannot extract answers
        explanation: nil,  # Python parser cannot extract explanations
        passage: passage_text,
        topic: q[:section],
        difficulty: nil,
        has_table: q[:table].present?,
        has_image: false,  # TODO: Detect images
        metadata: {
          section: q[:section],
          table: q[:table],
          passage_items: q[:passage]&.size || 0,
          choices_count: q[:choices]&.size || 0
        }
      }
    end
  end
end
