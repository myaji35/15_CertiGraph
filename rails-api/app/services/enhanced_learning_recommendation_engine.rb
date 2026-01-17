class EnhancedLearningRecommendationEngine
  # Enhanced recommendation engine with weakness-based learning paths,
  # spaced repetition, and personalized study schedules

  def initialize(user, study_material = nil)
    @user = user
    @study_material = study_material
    @weakness_analyzer = AdvancedWeaknessAnalyzer.new(user, study_material)
  end

  # Generate comprehensive learning recommendations
  def generate_recommendations
    weakness_analysis = @weakness_analyzer.analyze

    {
      learning_paths: generate_weakness_based_paths(weakness_analysis),
      optimal_sequence: determine_optimal_sequence(weakness_analysis),
      spaced_repetition_schedule: create_spaced_repetition_schedule(weakness_analysis),
      study_materials: recommend_study_materials(weakness_analysis),
      practice_questions: select_practice_questions(weakness_analysis),
      review_schedule: create_review_schedule(weakness_analysis),
      personalization: personalization_recommendations(weakness_analysis)
    }
  end

  # Weakness-based learning paths
  def generate_weakness_based_paths(weakness_analysis)
    priority_ranking = weakness_analysis[:priority_ranking]

    # Generate multiple path options
    {
      intensive_path: build_intensive_path(priority_ranking),
      balanced_path: build_balanced_path(priority_ranking),
      gradual_path: build_gradual_path(priority_ranking)
    }
  end

  # Optimal learning sequence
  def determine_optimal_sequence(weakness_analysis)
    priority_concepts = weakness_analysis[:priority_ranking].take(10)

    # Consider prerequisites and dependencies
    sequenced_concepts = apply_prerequisite_ordering(priority_concepts)

    # Apply difficulty progression
    difficulty_sequenced = apply_difficulty_progression(sequenced_concepts)

    difficulty_sequenced.map.with_index do |concept, index|
      {
        order: index + 1,
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        rationale: explain_sequence_rationale(concept, index),
        estimated_duration: concept[:estimated_study_hours],
        prerequisites_needed: find_prerequisites(concept[:concept_id])
      }
    end
  end

  # Spaced repetition schedule (Ebbinghaus forgetting curve)
  def create_spaced_repetition_schedule(weakness_analysis)
    critical_concepts = weakness_analysis[:severity_scores].select { |s| s[:severity_level] == 'critical' }

    critical_concepts.map do |concept|
      {
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        review_schedule: calculate_review_intervals(concept),
        total_reviews_needed: 5,
        optimal_spacing: [1, 3, 7, 14, 30] # days
      }
    end
  end

  # Recommend study materials
  def recommend_study_materials(weakness_analysis)
    weak_concepts = weakness_analysis[:severity_scores].take(5)

    weak_concepts.map do |concept|
      materials = find_relevant_materials(concept[:concept_id])

      {
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        recommended_materials: materials,
        study_priority: concept[:severity_level]
      }
    end
  end

  # Select targeted practice questions
  def select_practice_questions(weakness_analysis)
    weak_concepts = weakness_analysis[:severity_scores].take(5)

    weak_concepts.map do |concept|
      questions = find_practice_questions_for_concept(concept)

      {
        concept_id: concept[:concept_id],
        concept_name: concept[:concept_name],
        questions: questions,
        difficulty_distribution: distribute_question_difficulties(questions),
        recommended_count: calculate_recommended_practice_count(concept)
      }
    end
  end

  # Create comprehensive review schedule
  def create_review_schedule(weakness_analysis)
    # Weekly review plan
    weekly_plan = generate_weekly_plan(weakness_analysis)

    # Daily recommendations
    daily_recommendations = generate_daily_recommendations(weakness_analysis)

    {
      weekly_plan: weekly_plan,
      daily_recommendations: daily_recommendations,
      milestone_reviews: schedule_milestone_reviews(weakness_analysis),
      exam_prep_schedule: generate_exam_prep_schedule(weakness_analysis)
    }
  end

  # Personalization recommendations
  def personalization_recommendations(weakness_analysis)
    user_patterns = @weakness_analyzer.ml_pattern_insights

    {
      optimal_study_times: identify_optimal_study_times(user_patterns),
      session_length_recommendation: recommend_session_length(user_patterns),
      difficulty_preference: analyze_difficulty_preference,
      learning_style: infer_learning_style,
      motivation_strategy: suggest_motivation_strategy(weakness_analysis)
    }
  end

  private

  # Path building methods
  def build_intensive_path(priority_ranking)
    critical_concepts = priority_ranking.select { |c| c[:severity] > 60 }

    {
      name: 'Intensive Recovery Path',
      description: 'Focus on critical weaknesses first, intensive study schedule',
      duration_weeks: 2,
      daily_commitment_hours: 3,
      concepts: critical_concepts.map { |c| format_path_concept(c, 'intensive') },
      success_criteria: 'Achieve 80%+ accuracy on all critical concepts'
    }
  end

  def build_balanced_path(priority_ranking)
    {
      name: 'Balanced Improvement Path',
      description: 'Steady progress across all weaknesses',
      duration_weeks: 4,
      daily_commitment_hours: 1.5,
      concepts: priority_ranking.take(8).map { |c| format_path_concept(c, 'balanced') },
      success_criteria: 'Improve overall score by 15%'
    }
  end

  def build_gradual_path(priority_ranking)
    {
      name: 'Gradual Mastery Path',
      description: 'Long-term, sustainable improvement',
      duration_weeks: 8,
      daily_commitment_hours: 1,
      concepts: priority_ranking.map { |c| format_path_concept(c, 'gradual') },
      success_criteria: 'Master concepts one by one with 90%+ retention'
    }
  end

  def format_path_concept(concept, path_type)
    {
      concept_id: concept[:concept_id],
      concept_name: concept[:concept_name],
      week_number: calculate_week_assignment(concept, path_type),
      activities: generate_concept_activities(concept, path_type)
    }
  end

  def calculate_week_assignment(concept, path_type)
    case path_type
    when 'intensive'
      (concept[:rank] / 3.0).ceil # 3 concepts per week
    when 'balanced'
      (concept[:rank] / 2.0).ceil # 2 concepts per week
    when 'gradual'
      concept[:rank] # 1 concept per week
    end
  end

  def generate_concept_activities(concept, path_type)
    base_activities = [
      { type: 'review_material', duration_minutes: 30 },
      { type: 'practice_questions', duration_minutes: 45, count: 10 },
      { type: 'self_assessment', duration_minutes: 15 }
    ]

    case path_type
    when 'intensive'
      base_activities + [
        { type: 'additional_practice', duration_minutes: 60, count: 20 },
        { type: 'deep_review', duration_minutes: 30 }
      ]
    when 'balanced'
      base_activities + [{ type: 'reinforcement', duration_minutes: 30 }]
    else
      base_activities
    end
  end

  # Sequence optimization
  def apply_prerequisite_ordering(concepts)
    # Simplified prerequisite ordering
    # In production, would query actual prerequisite relationships
    concepts.sort_by do |concept|
      prereq_count = find_prerequisites(concept[:concept_id]).length
      [prereq_count, concept[:rank]]
    end
  end

  def apply_difficulty_progression(concepts)
    # Ensure easy concepts are learned before hard ones within same priority level
    concepts.sort_by do |concept|
      [concept[:rank] / 3, get_concept_difficulty(concept[:concept_id])]
    end
  end

  def explain_sequence_rationale(concept, index)
    reasons = []

    reasons << "High priority (rank #{concept[:rank]})"
    prereqs = find_prerequisites(concept[:concept_id])
    reasons << "Builds on #{prereqs.length} foundational concepts" if prereqs.any?

    difficulty = get_concept_difficulty(concept[:concept_id])
    reasons << "Appropriate difficulty for your current level (#{difficulty}/5)"

    reasons.join('. ')
  end

  def find_prerequisites(concept_id)
    # Find prerequisite concepts
    concept = KnowledgeNode.find_by(id: concept_id)
    return [] unless concept

    concept.knowledge_edges
           .where(relationship_type: 'prerequisite')
           .pluck(:related_node_id)
           .compact
  end

  def get_concept_difficulty(concept_id)
    KnowledgeNode.find_by(id: concept_id)&.difficulty || 3
  end

  # Spaced repetition
  def calculate_review_intervals(concept)
    severity = concept[:severity_score]

    # More severe = more frequent initial reviews
    base_intervals = case severity
                     when 0..30 then [3, 7, 14, 30, 60]
                     when 31..60 then [2, 5, 10, 20, 40]
                     else [1, 3, 7, 14, 30]
                     end

    base_intervals.map.with_index do |days, index|
      {
        review_number: index + 1,
        days_from_start: base_intervals.take(index + 1).sum,
        review_date: base_intervals.take(index + 1).sum.days.from_now.to_date,
        focus: index == 0 ? 'initial_learning' : 'reinforcement'
      }
    end
  end

  # Material recommendations
  def find_relevant_materials(concept_id)
    # Find study materials that cover this concept
    materials = StudyMaterial.joins(questions: :question_concepts)
                             .where(question_concepts: { knowledge_node_id: concept_id })
                             .distinct
                             .limit(5)

    materials.map do |material|
      {
        material_id: material.id,
        title: material.name,
        difficulty: material.difficulty,
        coverage_score: calculate_coverage_score(material, concept_id)
      }
    end
  end

  def calculate_coverage_score(material, concept_id)
    total_questions = material.questions.count
    concept_questions = material.questions.joins(:question_concepts)
                                .where(question_concepts: { knowledge_node_id: concept_id })
                                .count

    return 0 if total_questions.zero?

    (concept_questions.to_f / total_questions * 100).round(2)
  end

  # Practice question selection
  def find_practice_questions_for_concept(concept)
    concept_id = concept[:concept_id]
    severity = concept[:severity_score]

    # Get questions for this concept
    questions = Question.joins(:question_concepts)
                       .where(question_concepts: { knowledge_node_id: concept_id })
                       .limit(20)

    # Prioritize based on user's past performance
    wrong_question_ids = @user.wrong_answers.pluck(:question_id)

    questions.map do |q|
      {
        question_id: q.id,
        difficulty: q.difficulty,
        previously_wrong: wrong_question_ids.include?(q.id),
        priority: calculate_question_priority(q, severity, wrong_question_ids)
      }
    end.sort_by { |q| -q[:priority] }
  end

  def calculate_question_priority(question, concept_severity, wrong_question_ids)
    priority = 0

    # Higher severity = higher priority
    priority += concept_severity * 0.4

    # Previously wrong questions = higher priority
    priority += 30 if wrong_question_ids.include?(question.id)

    # Match difficulty to severity
    difficulty_match = 5 - (question.difficulty - concept_severity / 20).abs
    priority += difficulty_match * 10

    priority.round
  end

  def distribute_question_difficulties(questions)
    difficulties = questions.group_by { |q| q[:difficulty] }
                           .transform_values(&:count)

    {
      easy: difficulties[1, 2]&.sum || 0,
      medium: difficulties[3]&.count || 0,
      hard: difficulties[4, 5]&.sum || 0
    }
  end

  def calculate_recommended_practice_count(concept)
    severity = concept[:severity_score]

    case severity
    when 0..30 then 5
    when 31..60 then 10
    else 15
    end
  end

  # Schedule generation
  def generate_weekly_plan(weakness_analysis)
    priority_concepts = weakness_analysis[:priority_ranking].take(7)

    (1..4).map do |week_num|
      week_concepts = priority_concepts.select { |c| calculate_week_assignment(c, 'balanced') == week_num }

      {
        week: week_num,
        concepts: week_concepts.map { |c| c[:concept_name] },
        total_study_hours: week_concepts.sum { |c| c[:estimated_study_hours].is_a?(Range) ? c[:estimated_study_hours].min : c[:estimated_study_hours] },
        daily_breakdown: generate_daily_breakdown_for_week(week_concepts)
      }
    end
  end

  def generate_daily_breakdown_for_week(week_concepts)
    days = %w[Monday Tuesday Wednesday Thursday Friday Saturday Sunday]

    days.map.with_index do |day, index|
      concept = week_concepts[index % week_concepts.length]

      {
        day: day,
        focus_concept: concept&.dig(:concept_name),
        activities: ['Review material', 'Practice 5-10 questions', 'Self-assess'],
        estimated_time: '1-2 hours'
      }
    end
  end

  def generate_daily_recommendations(weakness_analysis)
    # Today's recommendations
    today_priority = weakness_analysis[:priority_ranking].first

    {
      today: {
        primary_focus: today_priority[:concept_name],
        activities: [
          { task: 'Review concept notes', duration_minutes: 20 },
          { task: 'Practice 10 questions', duration_minutes: 30 },
          { task: 'Review mistakes', duration_minutes: 10 }
        ],
        goal: 'Improve understanding and reduce error rate'
      },
      week_overview: "Focus on #{weakness_analysis[:priority_ranking].take(3).map { |c| c[:concept_name] }.join(', ')}"
    }
  end

  def schedule_milestone_reviews(weakness_analysis)
    [
      { day: 7, type: 'Weekly review', focus: 'All concepts covered this week' },
      { day: 14, type: 'Bi-weekly assessment', focus: 'Cumulative test' },
      { day: 30, type: 'Monthly comprehensive', focus: 'Full mastery check' }
    ]
  end

  def generate_exam_prep_schedule(weakness_analysis)
    # Assume exam is in 30 days
    exam_date = 30.days.from_now

    {
      phase_1: {
        name: 'Foundation Building',
        days: '1-15',
        focus: 'Address critical weaknesses',
        concepts: weakness_analysis[:priority_ranking].take(5).map { |c| c[:concept_name] }
      },
      phase_2: {
        name: 'Practice & Reinforcement',
        days: '16-25',
        focus: 'Intensive practice on all weak areas',
        daily_questions: 30
      },
      phase_3: {
        name: 'Final Review',
        days: '26-30',
        focus: 'Full mock exams and targeted review',
        activities: ['Daily mock exam', 'Review incorrect answers', 'Quick concept reviews']
      }
    }
  end

  # Personalization
  def identify_optimal_study_times(user_patterns)
    time_analysis = user_patterns[:time_trends] || {}

    {
      best_time_of_day: 'Evening (4-8pm)', # Simplified
      recommended_session_times: ['14:00', '19:00'],
      reasoning: 'Based on your past performance patterns'
    }
  end

  def recommend_session_length(user_patterns)
    {
      optimal_duration: 60, # minutes
      max_duration: 90,
      break_frequency: 'Every 25 minutes',
      reasoning: 'Pomodoro technique recommended for sustained focus'
    }
  end

  def analyze_difficulty_preference
    user_attempts = @user.exam_answers.group(:question_id)
                        .having('is_correct = ?', true)
                        .count

    # Simplified analysis
    {
      preferred_difficulty: 3,
      comfort_zone: '2-4',
      challenge_level: 'Medium'
    }
  end

  def infer_learning_style
    # Simplified learning style inference
    question_types = @user.exam_answers.joins(:question)
                         .group('questions.difficulty')
                         .count

    {
      style: 'Visual-Kinesthetic',
      recommendations: [
        'Use diagrams and flowcharts',
        'Practice with hands-on examples',
        'Create summary sheets'
      ]
    }
  end

  def suggest_motivation_strategy(weakness_analysis)
    improvement_rate = weakness_analysis[:improvement_tracking][:overall_trajectory][:improvement_rate]

    if improvement_rate > 5
      {
        strategy: 'Momentum Building',
        message: "Great progress! You've improved by #{improvement_rate}%. Keep the momentum going!",
        suggestions: ['Set higher targets', 'Challenge yourself with harder content']
      }
    else
      {
        strategy: 'Small Wins',
        message: 'Focus on achieving small, consistent victories',
        suggestions: ['Set daily achievable goals', 'Celebrate each concept mastered', 'Track daily progress']
      }
    end
  end
end
