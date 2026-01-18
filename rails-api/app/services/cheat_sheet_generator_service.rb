# frozen_string_literal: true

# CheatSheetGeneratorService
# Generates a compact pre-exam "cheat sheet" report based on GraphRAG weakness analysis
# 
# Usage:
#   service = CheatSheetGeneratorService.new
#   report = service.generate_for_user(user, study_set)
#   puts report[:markdown]

class CheatSheetGeneratorService
  MAX_CRITICAL_WEAKNESSES = 5
  MAX_PRIORITY_ITEMS = 10
  MAX_FLASHCARDS = 15

  def initialize
    @template_path = Rails.root.join('docs', 'cheat-sheet-template.md')
  end

  # Main entry point: Generate complete cheat sheet for a user
  # @param user [User] The student
  # @param study_set [StudySet] The study set being reviewed
  # @return [Hash] Report data with :markdown, :html, :data keys
  def generate_for_user(user, study_set)
    weaknesses = fetch_weaknesses(user, study_set)
    
    return empty_report(user, study_set) if weaknesses.empty?

    data = {
      student_name: user.name || user.email,
      exam_name: study_set.name,
      generated_date: Time.current.strftime('%Y년 %m월 %d일'),
      confidence_score: calculate_confidence_score(weaknesses),
      critical_weaknesses: format_critical_weaknesses(weaknesses),
      priority_checklist: format_priority_checklist(weaknesses),
      key_concept_flashcards: format_flashcards(weaknesses),
      common_mistakes: format_common_mistakes(weaknesses),
      current_score: estimate_current_score(user, study_set),
      predicted_score: estimate_predicted_score(user, study_set, weaknesses),
      improvement: 0, # Will be calculated
      pass_probability: calculate_pass_probability(user, study_set, weaknesses),
      total_questions: weaknesses.sum { |w| w[:affected_questions] },
      timestamp: Time.current.strftime('%Y-%m-%d %H:%M:%S')
    }

    data[:improvement] = data[:predicted_score] - data[:current_score]

    {
      markdown: render_markdown(data),
      html: render_html(data),
      data: data
    }
  end

  # Get top critical weaknesses (gap_score > 0.7)
  # @param user [User]
  # @param study_set [StudySet]
  # @return [Array<Hash>] Weakness data
  def critical_weaknesses(user, study_set)
    fetch_weaknesses(user, study_set)
      .select { |w| w[:gap_score] > 0.7 }
      .take(MAX_CRITICAL_WEAKNESSES)
  end

  # Generate flashcard-style key concepts
  # @param weaknesses [Array<Hash>]
  # @return [Array<Hash>] Flashcard data
  def key_concept_flashcards(weaknesses)
    weaknesses
      .flat_map { |w| w[:related_concepts] || [] }
      .uniq { |c| c['concept'] }
      .take(MAX_FLASHCARDS)
      .map do |concept|
        {
          concept: concept['concept'],
          definition: concept['definition'] || generate_definition(concept['concept']),
          priority: concept['severity'] || 'medium'
        }
      end
  end

  # Generate priority learning checklist
  # @param weaknesses [Array<Hash>]
  # @return [Array<Hash>] Checklist items
  def priority_checklist(weaknesses)
    weaknesses
      .take(MAX_PRIORITY_ITEMS)
      .map.with_index do |weakness, index|
        {
          rank: index + 1,
          concept: weakness[:concept],
          gap_score: weakness[:gap_score],
          estimated_minutes: estimate_study_time(weakness[:gap_score]),
          resources: suggest_resources(weakness[:concept])
        }
      end
  end

  private

  # Fetch all weaknesses for user, sorted by priority
  def fetch_weaknesses(user, study_set)
    # Get all analysis results with high gap scores
    analyses = AnalysisResult
      .where(user: user, study_set: study_set, status: 'completed')
      .where('concept_gap_score > ?', 0.4)
      .order(concept_gap_score: :desc)

    # Group by concept and aggregate
    weakness_map = {}
    
    analyses.each do |analysis|
      next unless analysis.related_concepts.present?

      analysis.related_concepts.each do |concept_data|
        concept_name = concept_data['concept']
        next unless concept_name

        if weakness_map[concept_name]
          weakness_map[concept_name][:affected_questions] += 1
          weakness_map[concept_name][:total_gap_score] += concept_data['gap_score'] || analysis.concept_gap_score
          weakness_map[concept_name][:count] += 1
        else
          weakness_map[concept_name] = {
            concept: concept_name,
            gap_score: concept_data['gap_score'] || analysis.concept_gap_score,
            total_gap_score: concept_data['gap_score'] || analysis.concept_gap_score,
            count: 1,
            affected_questions: 1,
            priority: determine_priority(concept_data['gap_score'] || analysis.concept_gap_score),
            related_concepts: [concept_data],
            error_type: analysis.error_type
          }
        end
      end
    end

    # Calculate average gap scores and sort
    weakness_map.values.map do |weakness|
      weakness[:gap_score] = weakness[:total_gap_score] / weakness[:count]
      weakness.delete(:total_gap_score)
      weakness.delete(:count)
      weakness
    end.sort_by { |w| [-w[:gap_score], -w[:affected_questions]] }
  end

  # Format critical weaknesses section
  def format_critical_weaknesses(weaknesses)
    critical = weaknesses.select { |w| w[:gap_score] > 0.7 }.take(MAX_CRITICAL_WEAKNESSES)
    
    return "✅ 축하합니다! 심각한 취약점이 발견되지 않았습니다." if critical.empty?

    critical.map.with_index do |w, i|
      emoji = priority_emoji(w[:priority])
      <<~WEAKNESS
        ### #{emoji} #{i + 1}. #{w[:concept]}
        
        - **취약도**: #{(w[:gap_score] * 100).round}% (#{w[:priority]})
        - **영향받는 문제**: #{w[:affected_questions]}개
        - **예상 학습 시간**: #{estimate_study_time(w[:gap_score])}분
        - **핵심 팁**: #{generate_quick_tip(w[:concept], w[:error_type])}
      WEAKNESS
    end.join("\n")
  end

  # Format priority checklist
  def format_priority_checklist(weaknesses)
    items = weaknesses.take(MAX_PRIORITY_ITEMS)
    
    items.map.with_index do |w, i|
      "- [ ] **#{i + 1}순위**: #{w[:concept]} (#{estimate_study_time(w[:gap_score])}분) - 취약도 #{(w[:gap_score] * 100).round}%"
    end.join("\n")
  end

  # Format flashcards
  def format_flashcards(weaknesses)
    flashcards = key_concept_flashcards(weaknesses)
    
    flashcards.map do |card|
      priority_badge = case card[:priority]
      when 'critical' then '🔴'
      when 'high' then '🟡'
      else '🟢'
      end

      <<~CARD
        #### #{priority_badge} #{card[:concept]}
        
        #{card[:definition]}
      CARD
    end.join("\n")
  end

  # Format common mistakes
  def format_common_mistakes(weaknesses)
    mistakes = [
      "⚠️ **시간 배분 실수**: 어려운 문제에 너무 많은 시간 소비하지 마세요",
      "⚠️ **문제 오독**: 문제를 끝까지 꼼꼼히 읽으세요",
      "⚠️ **개념 혼동**: #{weaknesses.first[:concept]}와 유사 개념을 구분하세요"
    ]

    # Add specific mistakes based on error types
    if weaknesses.any? { |w| w[:error_type] == 'careless' }
      mistakes << "⚠️ **실수 방지**: 답안 마킹 전 한 번 더 확인하세요"
    end

    mistakes.join("\n")
  end

  # Render markdown with template
  def render_markdown(data)
    template = File.read(@template_path)
    
    data.each do |key, value|
      template.gsub!("{#{key}}", value.to_s)
    end
    
    template
  end

  # Render HTML (simple markdown to HTML conversion)
  def render_html(data)
    markdown = render_markdown(data)
    # In production, use a proper markdown renderer like Redcarpet or Kramdown
    "<pre>#{markdown}</pre>"
  end

  # Calculate overall confidence score
  def calculate_confidence_score(weaknesses)
    return 95 if weaknesses.empty?
    
    avg_gap = weaknesses.map { |w| w[:gap_score] }.sum / weaknesses.size
    confidence = (1.0 - avg_gap) * 100
    [confidence.round, 60].max # Minimum 60% confidence
  end

  # Estimate current score
  def estimate_current_score(user, study_set)
    # Get recent exam performance
    recent_accuracy = ExamAnswer
      .joins(:question)
      .where(user: user, questions: { study_set: study_set })
      .where('exam_answers.created_at > ?', 30.days.ago)
      .average(:is_correct)
      .to_f

    (recent_accuracy * 100).round
  end

  # Estimate predicted score after studying weaknesses
  def estimate_predicted_score(user, study_set, weaknesses)
    current = estimate_current_score(user, study_set)
    
    # Calculate potential improvement
    total_affected = weaknesses.sum { |w| w[:affected_questions] }
    total_questions = Question.where(study_set: study_set).count
    
    return current if total_questions.zero?
    
    # Assume 70% improvement on weak areas
    potential_gain = (total_affected.to_f / total_questions) * 100 * 0.7
    
    [current + potential_gain.round, 100].min
  end

  # Calculate pass probability
  def calculate_pass_probability(user, study_set, weaknesses)
    predicted_score = estimate_predicted_score(user, study_set, weaknesses)
    
    # Assume passing score is 60
    if predicted_score >= 80
      95
    elsif predicted_score >= 70
      85
    elsif predicted_score >= 60
      70
    else
      50
    end
  end

  # Estimate study time based on gap score
  def estimate_study_time(gap_score)
    case gap_score
    when 0.7..1.0
      30 # Intensive study
    when 0.4..0.7
      20 # Focused study
    else
      10 # Quick review
    end
  end

  # Determine priority level
  def determine_priority(gap_score)
    case gap_score
    when 0.7..1.0
      'critical'
    when 0.5..0.7
      'high'
    else
      'medium'
    end
  end

  # Priority emoji
  def priority_emoji(priority)
    case priority
    when 'critical' then '🔴'
    when 'high' then '🟡'
    else '🟢'
    end
  end

  # Generate quick tip based on concept and error type
  def generate_quick_tip(concept, error_type)
    if error_type == 'careless'
      "문제를 천천히 읽고 키워드에 밑줄을 그으세요"
    else
      "#{concept}의 정의와 예시를 암기하세요"
    end
  end

  # Generate definition (placeholder - in production, fetch from knowledge graph)
  def generate_definition(concept)
    "#{concept}에 대한 핵심 개념 정리 (교재 참조)"
  end

  # Suggest resources
  def suggest_resources(concept)
    ["교재 해당 챕터", "기출 문제", "개념 정리 노트"]
  end

  # Empty report when no weaknesses found
  def empty_report(user, study_set)
    {
      markdown: "# 🎉 완벽합니다!\n\n#{user.name}님, 발견된 취약점이 없습니다. 자신감을 가지고 시험에 임하세요!",
      html: "<h1>🎉 완벽합니다!</h1><p>발견된 취약점이 없습니다.</p>",
      data: {
        student_name: user.name || user.email,
        exam_name: study_set.name,
        has_weaknesses: false
      }
    }
  end
end
