# Service for grading exams and calculating scores
class ExamGradingService
  attr_reader :exam_session, :results

  def initialize(exam_session)
    @exam_session = exam_session
    @results = {}
  end

  # Grade the exam and return results
  def grade
    return failure_result('시험 세션이 없습니다') unless exam_session

    ActiveRecord::Base.transaction do
      grade_all_answers
      calculate_statistics
      update_exam_session
      update_user_masteries
      create_wrong_answers

      success_result
    end
  rescue => e
    failure_result(e.message)
  end

  private

  def grade_all_answers
    @correct_count = 0
    @wrong_count = 0
    @unanswered_count = 0

    exam_session.exam_answers.includes(:question).each do |answer|
      if answer.selected_answer.blank?
        answer.update!(is_correct: false)
        @unanswered_count += 1
      else
        # Compare selected answer with correct answer
        is_correct = answer.selected_answer == answer.question.answer
        answer.update!(is_correct: is_correct)

        if is_correct
          @correct_count += 1
        else
          @wrong_count += 1
        end
      end
    end

    @results[:correct_count] = @correct_count
    @results[:wrong_count] = @wrong_count
    @results[:unanswered_count] = @unanswered_count
  end

  def calculate_statistics
    total_questions = exam_session.total_questions
    return if total_questions == 0

    @score = (@correct_count.to_f / total_questions * 100).round(2)
    @results[:score] = @score

    # Calculate by chapter
    @chapter_stats = calculate_chapter_statistics

    # Calculate by difficulty
    @difficulty_stats = calculate_difficulty_statistics

    # Calculate time per question
    @time_per_question = exam_session.time_elapsed.to_f / total_questions
    @results[:time_per_question] = @time_per_question
  end

  def calculate_chapter_statistics
    stats = {}

    exam_session.exam_answers.includes(:question).group_by { |a| a.question.chapter }.each do |chapter, answers|
      next unless chapter.present?

      total = answers.size
      correct = answers.count(&:is_correct)
      accuracy = total > 0 ? (correct.to_f / total * 100).round(1) : 0

      stats[chapter] = {
        total: total,
        correct: correct,
        wrong: total - correct,
        accuracy: accuracy
      }
    end

    @results[:chapter_stats] = stats
    stats
  end

  def calculate_difficulty_statistics
    stats = {}

    exam_session.exam_answers.includes(:question).group_by { |a| a.question.difficulty }.each do |difficulty, answers|
      next unless difficulty.present?

      total = answers.size
      correct = answers.count(&:is_correct)
      accuracy = total > 0 ? (correct.to_f / total * 100).round(1) : 0

      stats[difficulty] = {
        total: total,
        correct: correct,
        wrong: total - correct,
        accuracy: accuracy
      }
    end

    @results[:difficulty_stats] = stats
    stats
  end

  def update_exam_session
    exam_session.update!(
      score: @score,
      correct_answers: @correct_count,
      answered_questions: @correct_count + @wrong_count,
      completed_at: Time.current
    )
  end

  def update_user_masteries
    # Update user mastery for each concept tested
    exam_session.exam_answers.includes(question: :knowledge_nodes).each do |answer|
      next unless answer.question.knowledge_nodes.any?

      answer.question.knowledge_nodes.each do |node|
        mastery = UserMastery.find_or_initialize_by(
          user: exam_session.user,
          knowledge_node: node
        )

        # Update mastery based on answer correctness
        if answer.is_correct
          mastery.correct_count = (mastery.correct_count || 0) + 1
        else
          mastery.incorrect_count = (mastery.incorrect_count || 0) + 1
        end

        mastery.total_attempts = (mastery.total_attempts || 0) + 1
        mastery.last_attempted_at = Time.current

        # Calculate mastery percentage
        total = mastery.total_attempts
        correct = mastery.correct_count
        mastery.mastery_percentage = total > 0 ? (correct.to_f / total * 100).round(2) : 0

        # Update mastery status
        mastery.mastery_status = calculate_mastery_status(mastery.mastery_percentage)

        mastery.save!
      end
    end
  end

  def calculate_mastery_status(percentage)
    if percentage >= 80
      'mastered'
    elsif percentage >= 60
      'learning'
    else
      'weak'
    end
  end

  def create_wrong_answers
    # Create WrongAnswer records for incorrect answers
    exam_session.exam_answers.where(is_correct: false).includes(:question).each do |answer|
      next if answer.selected_answer.blank? # Skip unanswered

      wrong_answer = WrongAnswer.find_or_initialize_by(
        user: exam_session.user,
        question: answer.question,
        study_set: exam_session.study_set
      )

      wrong_answer.selected_answer = answer.selected_answer
      wrong_answer.attempt_count = (wrong_answer.attempt_count || 0) + 1
      wrong_answer.last_attempted_at = Time.current
      wrong_answer.save!
    end
  end

  def success_result
    {
      success: true,
      score: @score,
      correct_count: @correct_count,
      wrong_count: @wrong_count,
      unanswered_count: @unanswered_count,
      chapter_stats: @chapter_stats,
      difficulty_stats: @difficulty_stats,
      time_per_question: @time_per_question
    }
  end

  def failure_result(error_message)
    {
      success: false,
      error: error_message
    }
  end
end
