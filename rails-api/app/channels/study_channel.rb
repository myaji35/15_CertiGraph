# app/channels/study_channel.rb
# Handles real-time updates for study progress, PDF parsing, and learning analytics

class StudyChannel < ApplicationCable::Channel
  def subscribed
    # Stream from user-specific channel
    stream_for current_user

    # If specific study material is provided, stream from that too
    if params[:material_id]
      material = StudyMaterial.find_by(id: params[:material_id])
      stream_for material if material && material.user_id == current_user.id
    end

    # If specific exam session is provided
    if params[:exam_session_id]
      exam_session = ExamSession.find_by(id: params[:exam_session_id])
      stream_for exam_session if exam_session && exam_session.user_id == current_user.id
    end
  end

  def unsubscribed
    # Cleanup when channel is closed
    stop_all_streams
  end

  # Client can request progress update
  def request_progress(data)
    material = StudyMaterial.find_by(id: data['material_id'])
    return unless material && material.user_id == current_user.id

    broadcast_progress_update(material)
  end

  # Client can request statistics update
  def request_statistics
    statistics = calculate_user_statistics(current_user)

    StudyChannel.broadcast_to(
      current_user,
      {
        type: 'statistics_update',
        statistics: statistics,
        timestamp: Time.current.iso8601
      }
    )
  end

  private

  def broadcast_progress_update(material)
    StudyChannel.broadcast_to(
      material,
      {
        type: 'parsing_progress',
        material_id: material.id,
        status: material.parsing_status,
        progress: material.parsing_progress,
        message: status_message(material),
        timestamp: Time.current.iso8601
      }
    )
  end

  def calculate_user_statistics(user)
    {
      total_questions: user.questions.count,
      attempted_questions: user.question_attempts.distinct.count(:question_id),
      correct_answers: user.question_attempts.where(is_correct: true).count,
      accuracy_rate: calculate_accuracy(user),
      study_time: user.total_study_time_minutes,
      weak_concepts: user.weak_concepts.pluck(:name),
      strong_concepts: user.strong_concepts.pluck(:name)
    }
  end

  def calculate_accuracy(user)
    total = user.question_attempts.count
    return 0 if total.zero?

    correct = user.question_attempts.where(is_correct: true).count
    ((correct.to_f / total) * 100).round(2)
  end

  def status_message(material)
    case material.parsing_status
    when 'pending'
      'Waiting to start processing...'
    when 'processing'
      "Processing PDF... #{material.parsing_progress}%"
    when 'extracting_text'
      'Extracting text from PDF...'
    when 'parsing_questions'
      'Identifying questions and answers...'
    when 'generating_embeddings'
      'Generating AI embeddings...'
    when 'building_graph'
      'Building knowledge graph...'
    when 'completed'
      'Processing complete!'
    when 'failed'
      'Processing failed. Please try again.'
    else
      'Processing...'
    end
  end
end
