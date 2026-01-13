class TestScoringService
  def initialize(test_session)
    @test_session = test_session
  end

  def calculate_score
    total_questions = @test_session.question_count
    correct_answers = calculate_correct_answers

    # Calculate percentage score
    score = (correct_answers.to_f / total_questions * 100).round(2)

    # Update test session
    @test_session.update!(
      correct_answers: correct_answers,
      total_answered: count_answered_questions,
      score: score,
      results: generate_detailed_results
    )

    # Return analysis
    {
      score: score,
      correct_answers: correct_answers,
      total_questions: total_questions,
      pass: score >= passing_score,
      analysis: analyze_performance
    }
  end

  def analyze_weak_areas
    incorrect_questions = @test_session.test_questions
      .joins(:test_answer)
      .where(test_answers: { is_correct: false })
      .includes(:question)

    # Group by category/topic if available
    weak_topics = {}
    incorrect_questions.each do |test_question|
      topic = test_question.question.topic || 'General'
      weak_topics[topic] ||= { count: 0, questions: [] }
      weak_topics[topic][:count] += 1
      weak_topics[topic][:questions] << test_question.question_number
    end

    weak_topics.sort_by { |_, v| -v[:count] }.to_h
  end

  def generate_report
    {
      summary: {
        test_type: @test_session.test_type,
        score: @test_session.score,
        status: @test_session.pass? ? 'Pass' : 'Fail',
        time_taken: calculate_time_taken,
        questions_attempted: @test_session.total_answered,
        questions_correct: @test_session.correct_answers
      },
      performance: {
        accuracy_rate: calculate_accuracy,
        speed: calculate_speed,
        difficulty_analysis: analyze_by_difficulty
      },
      weak_areas: analyze_weak_areas,
      recommendations: generate_recommendations
    }
  end

  private

  def calculate_correct_answers
    @test_session.test_questions
      .joins(:test_answer)
      .where(test_answers: { is_correct: true })
      .count
  end

  def count_answered_questions
    @test_session.test_questions
      .joins(:test_answer)
      .count
  end

  def generate_detailed_results
    questions = @test_session.test_questions.includes(:test_answer, :question)

    {
      question_results: questions.map do |q|
        {
          question_number: q.question_number,
          answered: q.answered?,
          correct: q.correct?,
          selected_answer: q.test_answer&.selected_answer,
          correct_answer: q.correct_answer,
          time_spent: q.test_answer&.time_spent
        }
      end,
      statistics: {
        total_time: calculate_time_taken,
        average_time_per_question: calculate_average_time_per_question,
        accuracy: calculate_accuracy,
        completion_rate: calculate_completion_rate
      }
    }
  end

  def analyze_performance
    accuracy = calculate_accuracy
    speed = calculate_speed

    performance_level = if accuracy >= 90 && speed == 'fast'
                          'excellent'
                        elsif accuracy >= 70
                          'good'
                        elsif accuracy >= 50
                          'average'
                        else
                          'needs_improvement'
                        end

    {
      level: performance_level,
      accuracy: "#{accuracy}%",
      speed: speed,
      strengths: identify_strengths,
      weaknesses: identify_weaknesses
    }
  end

  def calculate_accuracy
    return 0 if @test_session.total_answered == 0

    (@test_session.correct_answers.to_f / @test_session.total_answered * 100).round(1)
  end

  def calculate_speed
    return 'not_timed' unless @test_session.time_limit.present?

    time_taken = calculate_time_taken
    time_limit_seconds = @test_session.time_limit * 60

    if time_taken < time_limit_seconds * 0.7
      'fast'
    elsif time_taken < time_limit_seconds * 0.9
      'moderate'
    else
      'slow'
    end
  end

  def calculate_time_taken
    return 0 unless @test_session.started_at && @test_session.completed_at

    (@test_session.completed_at - @test_session.started_at).to_i
  end

  def calculate_average_time_per_question
    return 0 if @test_session.total_answered == 0

    calculate_time_taken / @test_session.total_answered
  end

  def calculate_completion_rate
    (@test_session.total_answered.to_f / @test_session.question_count * 100).round(1)
  end

  def analyze_by_difficulty
    # This would analyze performance by question difficulty if available
    {
      easy: { attempted: 0, correct: 0 },
      medium: { attempted: 0, correct: 0 },
      hard: { attempted: 0, correct: 0 }
    }
  end

  def identify_strengths
    strengths = []

    strengths << "High accuracy (#{calculate_accuracy}%)" if calculate_accuracy >= 80
    strengths << "Fast completion" if calculate_speed == 'fast'
    strengths << "All questions attempted" if calculate_completion_rate == 100

    strengths.empty? ? ["Keep practicing"] : strengths
  end

  def identify_weaknesses
    weaknesses = []

    weaknesses << "Low accuracy (#{calculate_accuracy}%)" if calculate_accuracy < 60
    weaknesses << "Incomplete test" if calculate_completion_rate < 100
    weaknesses << "Time management" if calculate_speed == 'slow'

    weak_areas = analyze_weak_areas
    if weak_areas.any?
      top_weak = weak_areas.first[0]
      weaknesses << "Weak in #{top_weak}"
    end

    weaknesses.empty? ? ["None identified"] : weaknesses
  end

  def generate_recommendations
    recommendations = []
    accuracy = calculate_accuracy

    if accuracy < 60
      recommendations << "Review fundamental concepts thoroughly"
      recommendations << "Practice more questions in weak areas"
    elsif accuracy < 80
      recommendations << "Focus on problem areas identified"
      recommendations << "Take practice tests regularly"
    else
      recommendations << "Maintain your excellent performance"
      recommendations << "Challenge yourself with harder questions"
    end

    if calculate_speed == 'slow'
      recommendations << "Work on time management skills"
    end

    if calculate_completion_rate < 100
      recommendations << "Ensure you attempt all questions"
    end

    recommendations
  end

  def passing_score
    case @test_session.test_type
    when 'practice'
      60
    when 'mock_exam'
      70
    when 'review'
      80
    else
      70
    end
  end
end