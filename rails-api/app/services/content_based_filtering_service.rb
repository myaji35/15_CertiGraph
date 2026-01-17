# app/services/content_based_filtering_service.rb
class ContentBasedFilteringService
  attr_reader :user, :study_set

  def initialize(user, study_set = nil)
    @user = user
    @study_set = study_set
  end

  # Generate content-based recommendations
  def generate_recommendations(limit: 10)
    # Get user's learning profile
    user_profile = build_user_profile

    return [] if user_profile[:mastered_concepts].empty? && user_profile[:weak_concepts].empty?

    # Find questions matching user's interests and needs
    candidate_questions = find_candidate_questions(user_profile)

    # Score questions based on content similarity
    scored_questions = score_questions(candidate_questions, user_profile)

    # Apply diversity filter to avoid repetition
    diversified_questions = apply_diversity_filter(scored_questions, limit: limit)

    diversified_questions.take(limit).map do |q|
      {
        question_id: q[:question_id],
        score: q[:cb_score],
        reason: q[:reason],
        algorithm: 'content_based',
        confidence: q[:confidence],
        metadata: {
          matched_concepts: q[:matched_concepts],
          difficulty_match: q[:difficulty_match],
          novelty_score: q[:novelty_score]
        }
      }
    end
  end

  # Recommend questions based on user's weak concepts
  def weakness_based_recommendations(limit: 10)
    weak_concepts = identify_weak_concepts

    return [] if weak_concepts.empty?

    weak_concept_ids = weak_concepts.map { |c| c[:concept_id] }

    # Find questions that target weak concepts
    questions = Question.joins(:question_concepts)
                       .where(question_concepts: { knowledge_node_id: weak_concept_ids })
                       .group('questions.id')
                       .select('questions.*, COUNT(question_concepts.id) as concept_matches')

    # Filter to study set
    if study_set
      questions = questions.where(study_material_id: study_set.study_materials.pluck(:id))
    end

    # Exclude answered questions
    answered_ids = get_answered_question_ids
    questions = questions.where.not(id: answered_ids)

    questions.limit(limit * 2).map do |q|
      weakness_score = calculate_weakness_score(q, weak_concepts)

      {
        question_id: q.id,
        cb_score: weakness_score,
        reason: "약점 개념 보강: #{get_concept_names(q, weak_concept_ids).join(', ')}",
        confidence: 0.9,
        matched_concepts: get_concept_names(q, weak_concept_ids),
        difficulty_match: 1.0,
        novelty_score: 1.0
      }
    end.sort_by { |q| -q[:cb_score] }.take(limit)
  end

  # Recommend questions similar to those user liked
  def similar_content_recommendations(limit: 10)
    # Get questions user answered correctly recently
    liked_questions = get_liked_questions(limit: 20)

    return [] if liked_questions.empty?

    # Extract concepts from liked questions
    liked_concepts = extract_concepts_from_questions(liked_questions)

    return [] if liked_concepts.empty?

    # Find questions with similar concepts
    similar_questions = Question.joins(:question_concepts)
                               .where(question_concepts: { knowledge_node_id: liked_concepts.keys })
                               .where.not(id: liked_questions.map { |q| q[:question_id] })
                               .group('questions.id')
                               .select('questions.*, COUNT(question_concepts.id) as concept_matches')

    # Filter to study set
    if study_set
      similar_questions = similar_questions.where(study_material_id: study_set.study_materials.pluck(:id))
    end

    # Exclude answered questions
    answered_ids = get_answered_question_ids
    similar_questions = similar_questions.where.not(id: answered_ids)

    similar_questions.limit(limit * 2).map do |q|
      similarity_score = calculate_content_similarity(q, liked_concepts)

      {
        question_id: q.id,
        cb_score: similarity_score,
        reason: "선호하는 문제와 유사한 내용입니다",
        confidence: 0.8,
        matched_concepts: get_concept_names(q, liked_concepts.keys),
        difficulty_match: 1.0,
        novelty_score: 0.8
      }
    end.sort_by { |q| -q[:cb_score] }.take(limit)
  end

  # Recommend questions based on learning progression
  def progressive_recommendations(limit: 10)
    # Get concepts user is currently learning
    learning_concepts = get_learning_concepts

    return [] if learning_concepts.empty?

    # Find next-level concepts (prerequisites met)
    next_concepts = find_next_level_concepts(learning_concepts)

    return [] if next_concepts.empty?

    # Find questions for next-level concepts
    questions = Question.joins(:question_concepts)
                       .where(question_concepts: { knowledge_node_id: next_concepts.map { |c| c[:concept_id] } })
                       .group('questions.id')
                       .select('questions.*, COUNT(question_concepts.id) as concept_matches')

    # Filter to study set
    if study_set
      questions = questions.where(study_material_id: study_set.study_materials.pluck(:id))
    end

    # Exclude answered questions
    answered_ids = get_answered_question_ids
    questions = questions.where.not(id: answered_ids)

    questions.limit(limit * 2).map do |q|
      progression_score = calculate_progression_score(q, next_concepts)

      {
        question_id: q.id,
        cb_score: progression_score,
        reason: "다음 단계 학습: #{get_concept_names(q, next_concepts.map { |c| c[:concept_id] }).join(', ')}",
        confidence: 0.85,
        matched_concepts: get_concept_names(q, next_concepts.map { |c| c[:concept_id] }),
        difficulty_match: 1.0,
        novelty_score: 0.9
      }
    end.sort_by { |q| -q[:cb_score] }.take(limit)
  end

  private

  # Build user learning profile
  def build_user_profile
    masteries = user.user_masteries.includes(:knowledge_node)

    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      masteries = masteries.joins(:knowledge_node)
                          .where(knowledge_nodes: { study_material_id: material_ids })
    end

    {
      mastered_concepts: masteries.where(status: 'mastered').pluck(:knowledge_node_id),
      learning_concepts: masteries.where(status: 'learning').pluck(:knowledge_node_id),
      weak_concepts: masteries.where(status: 'weak').pluck(:knowledge_node_id),
      untested_concepts: masteries.where(status: 'untested').pluck(:knowledge_node_id),
      avg_mastery_level: masteries.average(:mastery_level) || 0.0,
      total_attempts: masteries.sum(:attempts)
    }
  end

  # Identify weak concepts
  def identify_weak_concepts
    masteries = user.user_masteries.includes(:knowledge_node)
                   .where(status: 'weak')
                   .order(mastery_level: :asc)

    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      masteries = masteries.joins(:knowledge_node)
                          .where(knowledge_nodes: { study_material_id: material_ids })
    end

    masteries.limit(10).map do |m|
      {
        concept_id: m.knowledge_node_id,
        concept_name: m.knowledge_node.name,
        mastery_level: m.mastery_level,
        gap_score: 1.0 - m.mastery_level
      }
    end
  end

  # Get concepts user is currently learning
  def get_learning_concepts
    masteries = user.user_masteries.includes(:knowledge_node)
                   .where(status: 'learning')

    if study_set
      material_ids = study_set.study_materials.pluck(:id)
      masteries = masteries.joins(:knowledge_node)
                          .where(knowledge_nodes: { study_material_id: material_ids })
    end

    masteries.map do |m|
      {
        concept_id: m.knowledge_node_id,
        concept_name: m.knowledge_node.name,
        mastery_level: m.mastery_level
      }
    end
  end

  # Find next-level concepts based on prerequisites
  def find_next_level_concepts(learning_concepts)
    learning_concept_ids = learning_concepts.map { |c| c[:concept_id] }

    # Find concepts that depend on learning concepts
    next_concepts = KnowledgeEdge.where(knowledge_node_id: learning_concept_ids)
                                 .where(relationship_type: 'prerequisite')
                                 .includes(:related_node)
                                 .map(&:related_node)
                                 .uniq

    # Check if user has not mastered these concepts yet
    mastered_ids = user.user_masteries.where(status: 'mastered').pluck(:knowledge_node_id)

    next_concepts.reject { |node| mastered_ids.include?(node.id) }
                .take(5)
                .map do |node|
      {
        concept_id: node.id,
        concept_name: node.name,
        prerequisite_concepts: learning_concept_ids
      }
    end
  end

  # Find candidate questions based on user profile
  def find_candidate_questions(user_profile)
    # Focus on weak concepts first, then learning concepts
    target_concepts = user_profile[:weak_concepts] + user_profile[:learning_concepts]

    return [] if target_concepts.empty?

    questions = Question.joins(:question_concepts)
                       .where(question_concepts: { knowledge_node_id: target_concepts })
                       .group('questions.id')
                       .select('questions.*, COUNT(question_concepts.id) as concept_matches')

    # Filter to study set
    if study_set
      questions = questions.where(study_material_id: study_set.study_materials.pluck(:id))
    end

    # Exclude answered questions
    answered_ids = get_answered_question_ids
    questions = questions.where.not(id: answered_ids)

    questions.limit(50).to_a
  end

  # Score questions based on content similarity to user profile
  def score_questions(questions, user_profile)
    questions.map do |q|
      # Get concepts for this question
      question_concepts = q.question_concepts.pluck(:knowledge_node_id)

      # Calculate scores
      relevance_score = calculate_relevance_score(question_concepts, user_profile)
      difficulty_match = calculate_difficulty_match(q, user_profile)
      novelty_score = calculate_novelty_score(q)

      # Combined content-based score
      cb_score = (relevance_score * 0.5 + difficulty_match * 0.3 + novelty_score * 0.2).round(2)

      # Determine reason
      reason = generate_reason(question_concepts, user_profile)

      {
        question_id: q.id,
        cb_score: cb_score,
        reason: reason,
        confidence: calculate_confidence(relevance_score, difficulty_match),
        matched_concepts: get_concept_names(q, question_concepts),
        difficulty_match: difficulty_match,
        novelty_score: novelty_score
      }
    end
  end

  # Calculate relevance to user's needs
  def calculate_relevance_score(question_concepts, user_profile)
    weak_matches = (question_concepts & user_profile[:weak_concepts]).size
    learning_matches = (question_concepts & user_profile[:learning_concepts]).size

    # Prioritize weak concepts
    (weak_matches * 10 + learning_matches * 5).to_f
  end

  # Calculate difficulty match
  def calculate_difficulty_match(question, user_profile)
    # Simple difficulty matching based on average mastery
    avg_mastery = user_profile[:avg_mastery_level]

    # Optimal difficulty is slightly above current mastery
    optimal_difficulty = avg_mastery + 0.1

    # Calculate how close question difficulty is to optimal
    # For now, use a default since questions don't have explicit difficulty
    0.7
  end

  # Calculate novelty score (how new/fresh the question is)
  def calculate_novelty_score(question)
    # Questions not answered yet get high novelty
    answered_ids = get_answered_question_ids

    answered_ids.include?(question.id) ? 0.0 : 1.0
  end

  # Generate recommendation reason
  def generate_reason(question_concepts, user_profile)
    weak_matches = question_concepts & user_profile[:weak_concepts]
    learning_matches = question_concepts & user_profile[:learning_concepts]

    if weak_matches.any?
      concept_names = KnowledgeNode.where(id: weak_matches.take(2)).pluck(:name)
      "약점 보강: #{concept_names.join(', ')}"
    elsif learning_matches.any?
      concept_names = KnowledgeNode.where(id: learning_matches.take(2)).pluck(:name)
      "학습 강화: #{concept_names.join(', ')}"
    else
      "관련 개념 학습"
    end
  end

  # Calculate confidence level
  def calculate_confidence(relevance_score, difficulty_match)
    if relevance_score > 15 && difficulty_match > 0.7
      0.9
    elsif relevance_score > 10
      0.8
    elsif relevance_score > 5
      0.7
    else
      0.6
    end
  end

  # Apply diversity filter to avoid similar questions
  def apply_diversity_filter(scored_questions, limit: 10)
    return scored_questions if scored_questions.size <= limit

    diversified = []
    used_concepts = Set.new

    scored_questions.each do |q|
      # Check if this question introduces new concepts
      question_concept_ids = QuestionConcept.where(question_id: q[:question_id])
                                           .pluck(:knowledge_node_id)

      new_concepts = question_concept_ids - used_concepts.to_a

      # Prioritize questions with new concepts
      if new_concepts.any? || diversified.size < limit * 0.5
        diversified << q
        used_concepts.merge(question_concept_ids)
      end

      break if diversified.size >= limit
    end

    # Fill remaining slots if needed
    remaining = limit - diversified.size
    if remaining > 0
      diversified += scored_questions.reject { |q| diversified.include?(q) }.take(remaining)
    end

    diversified
  end

  # Get questions user liked (answered correctly)
  def get_liked_questions(limit: 20)
    TestAnswer.joins(:test_question, test_question: :test_session)
             .where(test_sessions: { user_id: user.id })
             .where(is_correct: true)
             .order('test_answers.created_at DESC')
             .limit(limit)
             .pluck('test_questions.question_id')
             .map { |id| { question_id: id } }
  end

  # Extract concepts from questions
  def extract_concepts_from_questions(questions)
    question_ids = questions.map { |q| q[:question_id] }

    QuestionConcept.where(question_id: question_ids)
                  .group(:knowledge_node_id)
                  .count
  end

  # Calculate content similarity based on concept overlap
  def calculate_content_similarity(question, liked_concepts)
    question_concepts = QuestionConcept.where(question_id: question.id)
                                      .pluck(:knowledge_node_id)

    overlap = (question_concepts & liked_concepts.keys).size

    # Weight by concept frequency in liked questions
    weighted_score = overlap * 10

    weighted_score.to_f
  end

  # Calculate weakness-based score
  def calculate_weakness_score(question, weak_concepts)
    question_concept_ids = QuestionConcept.where(question_id: question.id)
                                         .pluck(:knowledge_node_id)

    weak_concept_ids = weak_concepts.map { |c| c[:concept_id] }
    matches = question_concept_ids & weak_concept_ids

    # Score based on number and severity of weak concept matches
    score = matches.sum do |concept_id|
      weak_concept = weak_concepts.find { |c| c[:concept_id] == concept_id }
      weak_concept ? weak_concept[:gap_score] * 20 : 0
    end

    score.round(2)
  end

  # Calculate progression score
  def calculate_progression_score(question, next_concepts)
    question_concept_ids = QuestionConcept.where(question_id: question.id)
                                         .pluck(:knowledge_node_id)

    next_concept_ids = next_concepts.map { |c| c[:concept_id] }
    matches = question_concept_ids & next_concept_ids

    # Higher score for more next-level concept matches
    (matches.size * 15).to_f
  end

  # Get concept names for a question
  def get_concept_names(question, concept_ids)
    KnowledgeNode.where(id: concept_ids)
                .joins(:question_concepts)
                .where(question_concepts: { question_id: question.id })
                .pluck(:name)
                .take(3)
  end

  # Get answered question IDs
  def get_answered_question_ids
    @answered_question_ids ||= begin
      TestAnswer.joins(:test_question, test_question: :test_session)
               .where(test_sessions: { user_id: user.id })
               .pluck('test_questions.question_id')
               .uniq
    end
  end
end
