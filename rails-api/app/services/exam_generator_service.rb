# Service for generating mock exams with various configuration options
class ExamGeneratorService
  attr_reader :study_set, :user, :options, :errors

  def initialize(study_set, user, options = {})
    @study_set = study_set
    @user = user
    @options = options.is_a?(ActionController::Parameters) ? options.to_h : options.with_indifferent_access
    @errors = []
  end

  # Main method to generate exam
  def generate
    validate_inputs
    return failure_result if @errors.any?

    ActiveRecord::Base.transaction do
      exam_session = create_exam_session
      questions = select_questions

      if questions.empty?
        @errors << '선택할 수 있는 문제가 없습니다'
        raise ActiveRecord::Rollback
      end

      create_exam_answers(exam_session, questions)

      success_result(exam_session)
    end
  rescue => e
    @errors << e.message
    failure_result
  end

  private

  def validate_inputs
    unless study_set
      @errors << '스터디 세트가 필요합니다'
      return
    end

    total_questions = study_set.study_materials.sum { |sm| sm.questions.count }
    unless total_questions > 0
      @errors << '문제가 없습니다. 먼저 PDF를 업로드하고 처리해주세요'
      return
    end

    question_count = options[:question_count].to_i
    if question_count <= 0
      @errors << '문제 수는 1개 이상이어야 합니다'
    end

    time_limit = options[:time_limit].to_i
    if time_limit <= 0
      @errors << '시간 제한은 1분 이상이어야 합니다'
    end
  end

  def create_exam_session
    exam_session = user.exam_sessions.create!(
      study_set: study_set,
      exam_type: options[:exam_type] || ExamSession::EXAM_TYPE_MOCK,
      time_limit: options[:time_limit].to_i,
      total_questions: 0, # Will update after selecting questions
      answered_questions: 0,
      correct_answers: 0,
      status: ExamSession::STATUS_IN_PROGRESS,
      started_at: nil, # Will be set when user actually starts
      randomization_enabled: options[:randomization_enabled] || false
    )

    # Store exam generation metadata
    exam_session.update_column(:metadata, {
      exam_title: options[:exam_title],
      category: options[:category],
      difficulty_distribution: difficulty_distribution,
      chapter_distribution: options[:chapter_distribution],
      past_questions_ratio: options[:past_questions_ratio],
      prevent_duplicates: options[:prevent_duplicates],
      days_to_check: options[:days_to_check]
    }.to_json)

    exam_session
  end

  def select_questions
    # Collect questions from all study_materials in the study_set
    all_question_ids = study_set.study_materials.includes(:questions).flat_map { |sm| sm.questions.pluck(:id) }
    base_query = Question.where(id: all_question_ids)

    # Apply validated scope if it exists
    base_query = base_query.validated if Question.respond_to?(:validated)

    # Apply duplicate prevention if requested
    if options[:prevent_duplicates] == '1' || options[:prevent_duplicates] == true
      days = options[:days_to_check].to_i
      days = 30 if days <= 0

      recent_question_ids = user.exam_sessions
                                 .where('created_at > ?', days.days.ago)
                                 .joins(exam_answers: :question)
                                 .pluck('questions.id')
                                 .uniq

      base_query = base_query.where.not(id: recent_question_ids)
    end

    # Apply chapter distribution if specified
    if options[:chapter_distribution].present?
      questions = select_by_chapter_distribution(base_query)
    # Apply difficulty distribution if specified
    elsif has_difficulty_distribution?
      questions = select_by_difficulty(base_query)
    # Apply past questions priority if specified
    elsif options[:prioritize_past_questions] == '1' || options[:prioritize_past_questions] == true
      questions = select_with_past_priority(base_query)
    else
      # Default: random selection
      question_count = options[:question_count].to_i
      questions = base_query.order('RANDOM()').limit(question_count).to_a
    end

    questions
  end

  def select_by_chapter_distribution(base_query)
    chapter_dist = options[:chapter_distribution] || {}
    selected_questions = []

    chapter_dist.each do |chapter_num, count|
      count = count.to_i
      next if count <= 0

      # Questions don't have 'chapter' field - use topic pattern matching instead
      chapter_questions = base_query.where("topic LIKE ?", "%챕터 #{chapter_num}%")
                                    .order('RANDOM()')
                                    .limit(count)
                                    .to_a

      selected_questions.concat(chapter_questions)
    end

    selected_questions
  end

  def select_by_difficulty(base_query)
    dist = difficulty_distribution
    question_count = options[:question_count].to_i

    easy_count = (question_count * dist[:easy] / 100.0).round
    medium_count = (question_count * dist[:medium] / 100.0).round
    hard_count = question_count - easy_count - medium_count

    selected_questions = []

    if easy_count > 0
      easy_qs = base_query.where(difficulty: ['easy', 'Easy', '쉬움'])
                          .order('RANDOM()')
                          .limit(easy_count)
                          .to_a
      selected_questions.concat(easy_qs)
    end

    if medium_count > 0
      medium_qs = base_query.where(difficulty: ['medium', 'Medium', '보통'])
                            .order('RANDOM()')
                            .limit(medium_count)
                            .to_a
      selected_questions.concat(medium_qs)
    end

    if hard_count > 0
      hard_qs = base_query.where(difficulty: ['hard', 'Hard', '어려움'])
                          .order('RANDOM()')
                          .limit(hard_count)
                          .to_a
      selected_questions.concat(hard_qs)
    end

    # If not enough questions with specific difficulties, fill with random
    if selected_questions.size < question_count
      remaining = question_count - selected_questions.size
      additional = base_query.where.not(id: selected_questions.map(&:id))
                             .order('RANDOM()')
                             .limit(remaining)
                             .to_a
      selected_questions.concat(additional)
    end

    selected_questions.shuffle
  end

  def select_with_past_priority(base_query)
    ratio = options[:past_questions_ratio].to_i
    ratio = 70 if ratio <= 0 || ratio > 100

    question_count = options[:question_count].to_i
    past_count = (question_count * ratio / 100.0).round
    regular_count = question_count - past_count

    selected_questions = []

    # Select past exam questions if the field exists
    if Question.column_names.include?('is_past_question')
      past_qs = base_query.where(is_past_question: true)
                          .order('RANDOM()')
                          .limit(past_count)
                          .to_a
      selected_questions.concat(past_qs)
    end

    # Fill remaining with regular questions
    remaining_count = question_count - selected_questions.size
    if remaining_count > 0
      regular_qs = base_query.where.not(id: selected_questions.map(&:id))
                             .order('RANDOM()')
                             .limit(remaining_count)
                             .to_a
      selected_questions.concat(regular_qs)
    end

    selected_questions.shuffle
  end

  def create_exam_answers(exam_session, questions)
    questions.each_with_index do |question, index|
      exam_session.exam_answers.create!(
        question: question,
        question_order: index + 1,
        selected_answer: nil,
        is_correct: false
      )
    end

    exam_session.update!(total_questions: questions.size)
  end

  def difficulty_distribution
    {
      easy: options[:difficulty_easy].to_i,
      medium: options[:difficulty_medium].to_i,
      hard: options[:difficulty_hard].to_i
    }
  end

  def has_difficulty_distribution?
    dist = difficulty_distribution
    dist.values.sum > 0
  end

  def success_result(exam_session)
    {
      success: true,
      exam_session: exam_session,
      message: '모의고사가 생성되었습니다'
    }
  end

  def failure_result
    {
      success: false,
      error: @errors.join(', ')
    }
  end
end
