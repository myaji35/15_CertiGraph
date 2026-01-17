# Passage Detection Service
# Automatically detects passages (reading comprehension sections) in markdown content
class PassageDetectionService
  PASSAGE_MARKERS = [
    /<!-- PASSAGE (\d+) START -->/,
    /\[지문 (\d+)\]/,
    /\[보기\]/,
    /\[문제 상황\]/,
    /\[Case Study\]/i
  ].freeze

  attr_reader :markdown_content

  def initialize(markdown_content)
    @markdown_content = markdown_content
  end

  # Detect all passages in the content
  # @return [Hash] { passages: Array, stats: Hash }
  def detect_passages
    return { passages: [], stats: {} } if @markdown_content.blank?

    lines = @markdown_content.split("\n")
    passages = []
    current_passage = nil
    passage_id_counter = 1

    lines.each_with_index do |line, index|
      # Check for passage start markers
      if passage_start?(line)
        # Save previous passage if exists
        if current_passage
          passages << finalize_passage(current_passage, passage_id_counter)
          passage_id_counter += 1
        end

        # Start new passage
        current_passage = {
          start_line: index,
          content_lines: [],
          type: detect_passage_type(line)
        }
      elsif passage_end?(line)
        # End current passage
        if current_passage
          passages << finalize_passage(current_passage, passage_id_counter)
          passage_id_counter += 1
          current_passage = nil
        end
      elsif current_passage
        # Add line to current passage
        current_passage[:content_lines] << line unless line.strip.empty?
      else
        # Check for implicit passages (large text blocks before questions)
        if implicit_passage_indicator?(line, lines, index)
          current_passage = {
            start_line: index,
            content_lines: [line],
            type: 'implicit'
          }
        end
      end
    end

    # Finalize last passage if exists
    if current_passage
      passages << finalize_passage(current_passage, passage_id_counter)
    end

    {
      passages: passages,
      stats: generate_passage_stats(passages)
    }
  end

  # Detect passage type based on content
  # @param line [String] The line to analyze
  # @return [String] Passage type
  def detect_passage_type(line)
    return 'case_study' if line.match?(/case study/i)
    return 'situation' if line.match?(/문제 상황|시나리오/)
    return 'reading' if line.match?(/지문|보기/)
    'text'
  end

  private

  def passage_start?(line)
    PASSAGE_MARKERS.any? { |pattern| line.match?(pattern) }
  end

  def passage_end?(line)
    line.match?(/<!-- PASSAGE \d+ END -->/) || line.match?(/\[\/지문\]/)
  end

  def implicit_passage_indicator?(line, lines, index)
    # Heuristics for detecting implicit passages:
    # 1. Paragraph is longer than 200 characters
    # 2. Followed by multiple questions within next 20 lines
    # 3. Contains narrative or descriptive content

    return false if line.length < 200

    # Look ahead for question patterns
    next_20_lines = lines[index + 1...[index + 21, lines.length].min] || []
    question_count = next_20_lines.count { |l| question_pattern?(l) }

    question_count >= 2
  end

  def question_pattern?(line)
    line.match?(/^\d{1,3}[\.)]\s+/) || line.match?(/^\(\d{1,3}\)\s+/)
  end

  def finalize_passage(passage_data, id)
    content = passage_data[:content_lines].join("\n")

    {
      id: id,
      content: content,
      type: passage_data[:type] || 'text',
      position: passage_data[:start_line],
      has_image: content.include?('![') || content.include?('[image'),
      has_table: content.include?('|') || content.match?(/\(\s*[ㄱ-ㅎ]\s*\)/),
      character_count: content.length,
      metadata: {
        line_count: passage_data[:content_lines].size,
        start_line: passage_data[:start_line]
      }
    }
  end

  def generate_passage_stats(passages)
    return {} if passages.empty?

    {
      total_passages: passages.size,
      passages_with_images: passages.count { |p| p[:has_image] },
      passages_with_tables: passages.count { |p| p[:has_table] },
      avg_character_count: passages.sum { |p| p[:character_count] } / passages.size,
      passage_types: passages.group_by { |p| p[:type] }.transform_values(&:count)
    }
  end
end
