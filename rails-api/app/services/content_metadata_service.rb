class ContentMetadataService
  attr_reader :study_material, :errors

  def initialize(study_material)
    @study_material = study_material
    @errors = []
  end

  def extract_metadata
    return false unless valid_for_extraction?

    begin
      metadata = build_metadata

      study_material.update!(content_metadata: metadata)
      true
    rescue StandardError => e
      @errors << "Metadata extraction failed: #{e.message}"
      Rails.logger.error("ContentMetadataService Error: #{e.message}\n#{e.backtrace.join("\n")}")
      false
    end
  end

  def self.extract_batch(study_materials)
    results = { success: [], failed: [] }

    study_materials.each do |material|
      service = new(material)
      if service.extract_metadata
        results[:success] << material
      else
        results[:failed] << { material: material, errors: service.errors }
      end
    end

    results
  end

  private

  def valid_for_extraction?
    if study_material.nil?
      @errors << "Study material is nil"
      return false
    end

    unless study_material.status == 'completed'
      @errors << "Study material must be in 'completed' status"
      return false
    end

    true
  end

  def build_metadata
    metadata = study_material.content_metadata || {}

    # Document statistics
    metadata.merge!(extract_document_stats)

    # Exam information
    metadata.merge!(extract_exam_info)

    # Content structure
    metadata.merge!(extract_content_structure)

    # Difficulty analysis
    metadata.merge!(analyze_difficulty)

    # Timestamps
    metadata[:metadata_extracted_at] = Time.current.iso8601
    metadata[:metadata_version] = '1.0'

    metadata
  end

  def extract_document_stats
    {
      total_questions: study_material.questions.count,
      total_chunks: study_material.document_chunks.count,
      total_knowledge_nodes: study_material.knowledge_nodes.count,
      has_pdf: study_material.pdf_file.attached?,
      pdf_filename: study_material.pdf_file.attached? ? study_material.pdf_file.filename.to_s : nil,
      pdf_size_bytes: study_material.pdf_file.attached? ? study_material.pdf_file.byte_size : nil,
      pdf_content_type: study_material.pdf_file.attached? ? study_material.pdf_file.content_type : nil
    }
  end

  def extract_exam_info
    info = {}

    # Try to extract from filename
    filename = study_material.name || ''

    # Extract year (e.g., "2023년", "2023", "23년")
    year_match = filename.match(/(\d{4})년?|년도?\s*(\d{4})|'(\d{2})/)
    if year_match
      year = year_match[1] || year_match[2] || "20#{year_match[3]}"
      info[:exam_year] = year.to_i
    end

    # Extract round/회차 (e.g., "1회", "2차")
    round_match = filename.match(/(\d+)회|(\d+)차/)
    if round_match
      info[:exam_round] = (round_match[1] || round_match[2]).to_i
    end

    # Extract certification name
    info[:certification_name] = extract_certification_name(filename)

    # Extract exam type
    info[:exam_type] = extract_exam_type(filename)

    # Extract issuing organization
    info[:issuing_organization] = extract_organization(filename)

    info
  end

  def extract_certification_name(text)
    # Common patterns for Korean certifications
    patterns = [
      /정보처리(산업)?기사/,
      /정보처리기능사/,
      /전기(산업)?기사/,
      /건축(산업)?기사/,
      /소방(설비)?기사/,
      /위험물(산업)?기사/,
      /공인중개사/,
      /세무사/,
      /회계사/,
      /기능장/,
      /기사/,
      /산업기사/,
      /기능사/
    ]

    patterns.each do |pattern|
      match = text.match(pattern)
      return match[0] if match
    end

    nil
  end

  def extract_exam_type(text)
    return 'practical' if text.match?(/실기|실습/)
    return 'written' if text.match?(/필기|이론/)
    'unknown'
  end

  def extract_organization(text)
    orgs = {
      'Q-Net' => /q-?net|큐넷|한국산업인력공단/i,
      'HRD Korea' => /hrd|인적자원개발/i,
      'KISA' => /kisa|한국인터넷진흥원/i,
      'KAIT' => /kait|한국정보통신진흥협회/i
    }

    orgs.each do |org_name, pattern|
      return org_name if text.match?(pattern)
    end

    nil
  end

  def extract_content_structure
    structure = {
      has_chapters: false,
      has_sections: false,
      has_images: false,
      has_tables: false
    }

    # Analyze knowledge nodes for structure
    nodes = study_material.knowledge_nodes
    if nodes.any?
      structure[:has_chapters] = nodes.where(level: 'chapter').exists?
      structure[:has_sections] = nodes.where(level: 'section').exists?
    end

    # Check extracted data
    if study_material.extracted_data.present?
      data = study_material.extracted_data
      structure[:has_images] = data.dig('images')&.any? || false
      structure[:has_tables] = data.dig('tables')&.any? || false

      # Extract chapter/section info if available
      if data.dig('table_of_contents').present?
        structure[:table_of_contents] = data['table_of_contents']
      end
    end

    structure
  end

  def analyze_difficulty
    analysis = {
      estimated_difficulty: study_material.difficulty || 3,
      difficulty_factors: []
    }

    questions = study_material.questions

    if questions.any?
      # Average question length
      avg_length = questions.average('LENGTH(question_text)').to_i
      if avg_length > 200
        analysis[:difficulty_factors] << 'long_questions'
      end

      # Check for complex question types
      options_count = questions.joins(:options).group('questions.id').count
      if options_count.any? { |_, count| count > 4 }
        analysis[:difficulty_factors] << 'many_options'
      end

      # Calculate question complexity score
      analysis[:avg_question_length] = avg_length
      analysis[:total_questions] = questions.count
    end

    # Check knowledge graph complexity
    nodes_count = study_material.knowledge_nodes.count
    edges_count = study_material.knowledge_nodes.joins(:knowledge_edges).count

    if nodes_count > 50
      analysis[:difficulty_factors] << 'complex_knowledge_graph'
    end

    analysis[:knowledge_nodes_count] = nodes_count
    analysis[:knowledge_edges_count] = edges_count

    # Overall complexity score (0-100)
    complexity_score = calculate_complexity_score(avg_length, questions.count, nodes_count)
    analysis[:complexity_score] = complexity_score

    analysis
  end

  def calculate_complexity_score(avg_length, questions_count, nodes_count)
    score = 0

    # Question length contribution (0-30 points)
    score += [[avg_length / 10, 30].min, 0].max

    # Questions count contribution (0-30 points)
    score += [[questions_count / 3, 30].min, 0].max

    # Knowledge graph contribution (0-40 points)
    score += [[nodes_count / 2, 40].min, 0].max

    [score.to_i, 100].min
  end

  # Extract page count from PDF if available
  def extract_page_count
    return nil unless study_material.pdf_file.attached?

    begin
      # This would require pdf-reader gem or similar
      # For now, we'll estimate based on file size
      # Roughly 50KB per page average
      file_size = study_material.pdf_file.byte_size
      estimated_pages = (file_size / 50_000).round

      { estimated_pages: estimated_pages }
    rescue StandardError => e
      Rails.logger.error("Page count extraction failed: #{e.message}")
      nil
    end
  end

  # Generate summary statistics
  def generate_summary
    metadata = study_material.content_metadata || {}

    summary = {
      title: study_material.name,
      category: ContentClassificationService.category_name(study_material.category),
      difficulty: ContentClassificationService.difficulty_name(study_material.difficulty),
      total_questions: metadata[:total_questions],
      exam_year: metadata[:exam_year],
      exam_round: metadata[:exam_round],
      complexity_score: metadata.dig(:complexity_score)
    }

    summary.compact
  end

  # Class method to regenerate all metadata
  def self.regenerate_all
    StudyMaterial.where(status: 'completed').find_each do |material|
      service = new(material)
      service.extract_metadata
    end
  end
end
