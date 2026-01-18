# Passage Detection Service
# Detects and extracts passages (지문) from markdown content
class PassageDetectionService
  attr_reader :markdown_content, :passages

  def initialize(markdown_content)
    @markdown_content = markdown_content
    @passages = []
  end

  # Detect and extract all passages
  # @return [Hash] { passages: Array, stats: Hash }
  def detect_passages
    return { passages: [], stats: {} } if @markdown_content.blank?

    # Method 1: HTML comment-based detection (<!-- PASSAGE n START/END -->)
    html_passages = extract_html_comment_passages

    # Method 2: Pattern-based detection ("다음을 읽고", "아래 글을 읽고")
    pattern_passages = extract_pattern_based_passages

    # Combine and deduplicate
    all_passages = (html_passages + pattern_passages).uniq { |p| p[:content] }

    # Assign unique IDs
    all_passages.each_with_index do |passage, index|
      passage[:id] = index + 1
    end

    @passages = all_passages

    {
      passages: @passages,
      stats: {
        total_passages: @passages.size,
        html_comment_based: html_passages.size,
        pattern_based: pattern_passages.size,
        has_images: @passages.count { |p| p[:has_image] },
        has_tables: @passages.count { |p| p[:has_table] }
      }
    }
  end

  private

  # Extract passages marked with HTML comments
  def extract_html_comment_passages
    passages = []
    pattern = /<!-- PASSAGE (\d+) START -->\s*(.*?)\s*<!-- PASSAGE \1 END -->/m

    @markdown_content.scan(pattern) do |passage_num, content|
      passages << {
        content: content.strip,
        type: 'text',
        position: passage_num.to_i,
        has_image: content.include?('!['),
        has_table: content.include?('|') && content.include?('---'),
        metadata: {
          source: 'html_comment',
          passage_number: passage_num.to_i
        }
      }
    end

    passages
  end

  # Extract passages based on Korean patterns
  def extract_pattern_based_passages
    passages = []

    patterns = [
      /(?:다음|아래)\s*(?:을|를)?\s*읽고.+?(?=\n\n|\d+\.|①|$)/m,
      /(?:다음|아래)\s*글을\s*읽고.+?(?=\n\n|\d+\.|①|$)/m
    ]

    position = 1000

    patterns.each do |pattern|
      @markdown_content.scan(pattern) do |match|
        content = match.is_a?(Array) ? match[0] : match
        next if content.blank?

        passages << {
          content: content.strip,
          type: 'text',
          position: position,
          has_image: content.include?('!['),
          has_table: content.include?('|') && content.include?('---'),
          metadata: { source: 'pattern_based' }
        }

        position += 1
      end
    end

    passages
  end
end
