class TrainMlModelJob < ApplicationJob
  queue_as :default

  # Train ML models for pattern detection and weakness analysis
  def perform(model_id)
    model = MlModel.find(model_id)

    Rails.logger.info("[TrainMlModelJob] Starting training for model #{model.id} (#{model.model_type})")

    model.start_training!

    begin
      case model.model_type
      when 'pattern_classifier'
        train_pattern_classifier(model)
      when 'error_predictor'
        train_error_predictor(model)
      when 'time_series'
        train_time_series_model(model)
      when 'anomaly_detector'
        train_anomaly_detector(model)
      else
        raise "Unknown model type: #{model.model_type}"
      end

      model.mark_trained!

      Rails.logger.info("[TrainMlModelJob] Successfully trained model #{model.id}")
    rescue StandardError => e
      Rails.logger.error("[TrainMlModelJob] Training failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      model.update!(
        status: 'untrained',
        metadata: model.metadata.merge(
          last_training_error: e.message,
          last_training_attempt: Time.current
        )
      )

      raise
    end
  end

  private

  def train_pattern_classifier(model)
    # Gather training data from all users
    training_data = gather_pattern_training_data

    Rails.logger.info("[TrainMlModelJob] Gathered #{training_data.length} training samples")

    return if training_data.length < 100 # Minimum required

    # Use OpenAI to analyze patterns and build classification model
    openai_client = OpenaiClient.new

    prompt = build_classification_training_prompt(training_data)

    response = openai_client.chat(
      messages: [{ role: 'user', content: prompt }],
      model: 'gpt-4o',
      response_format: { type: 'json_object' }
    )

    result = JSON.parse(response['choices'][0]['message']['content'])

    # Store model parameters and performance metrics
    model.update!(
      training_samples_count: training_data.length,
      model_parameters: result['parameters'] || {},
      model_weights: result['weights'] || {},
      feature_importance: result['feature_importance'] || {},
      accuracy: result['accuracy'].to_f,
      precision: result['precision'].to_f,
      recall: result['recall'].to_f,
      f1_score: result['f1_score'].to_f,
      confusion_matrix: result['confusion_matrix'] || {},
      features: extract_feature_names,
      training_history: (model.training_history || []) + [{
        trained_at: Time.current,
        accuracy: result['accuracy'],
        samples: training_data.length
      }]
    )
  end

  def train_error_predictor(model)
    # Gather error prediction training data
    training_data = gather_error_prediction_data

    Rails.logger.info("[TrainMlModelJob] Gathered #{training_data.length} error prediction samples")

    return if training_data.length < 50

    openai_client = OpenaiClient.new

    prompt = build_error_prediction_prompt(training_data)

    response = openai_client.chat(
      messages: [{ role: 'user', content: prompt }],
      model: 'gpt-4o',
      response_format: { type: 'json_object' }
    )

    result = JSON.parse(response['choices'][0]['message']['content'])

    model.update!(
      training_samples_count: training_data.length,
      model_parameters: result['parameters'] || {},
      accuracy: result['accuracy'].to_f,
      precision: result['precision'].to_f,
      recall: result['recall'].to_f,
      features: ['mastery_level', 'previous_errors', 'difficulty', 'time_spent'],
      training_history: (model.training_history || []) + [{
        trained_at: Time.current,
        accuracy: result['accuracy']
      }]
    )
  end

  def train_time_series_model(model)
    # Gather time series data
    time_series_data = gather_time_series_data

    Rails.logger.info("[TrainMlModelJob] Gathered time series data with #{time_series_data.length} points")

    return if time_series_data.length < 30

    openai_client = OpenaiClient.new

    prompt = build_time_series_prompt(time_series_data)

    response = openai_client.chat(
      messages: [{ role: 'user', content: prompt }],
      model: 'gpt-4o',
      response_format: { type: 'json_object' }
    )

    result = JSON.parse(response['choices'][0]['message']['content'])

    model.update!(
      training_samples_count: time_series_data.length,
      model_parameters: result['parameters'] || {},
      mae: result['mae'].to_f,
      rmse: result['rmse'].to_f,
      features: ['timestamp', 'error_count', 'accuracy', 'session_count'],
      training_history: (model.training_history || []) + [{
        trained_at: Time.current,
        mae: result['mae'],
        rmse: result['rmse']
      }]
    )
  end

  def train_anomaly_detector(model)
    # Gather normal behavior data
    normal_data = gather_normal_behavior_data

    Rails.logger.info("[TrainMlModelJob] Gathered #{normal_data.length} normal behavior samples")

    return if normal_data.length < 100

    openai_client = OpenaiClient.new

    prompt = build_anomaly_detection_prompt(normal_data)

    response = openai_client.chat(
      messages: [{ role: 'user', content: prompt }],
      model: 'gpt-4o',
      response_format: { type: 'json_object' }
    )

    result = JSON.parse(response['choices'][0]['message']['content'])

    model.update!(
      training_samples_count: normal_data.length,
      model_parameters: result['parameters'] || {},
      accuracy: result['accuracy'].to_f,
      precision: result['precision'].to_f,
      recall: result['recall'].to_f,
      features: ['accuracy', 'time_per_question', 'completion_rate', 'score'],
      training_history: (model.training_history || []) + [{
        trained_at: Time.current,
        accuracy: result['accuracy']
      }]
    )
  end

  # Data gathering methods
  def gather_pattern_training_data
    WrongAnswer.joins(:question, :user)
               .includes(question: :question_concepts)
               .where('wrong_answers.created_at > ?', 90.days.ago)
               .limit(1000)
               .map do |wa|
      {
        error_id: wa.id,
        user_id: wa.user_id,
        difficulty: wa.question.difficulty || 3,
        topic: wa.question.topic,
        attempt_count: wa.attempt_count || 1,
        time_of_day: wa.last_attempted_at.hour,
        day_of_week: wa.last_attempted_at.wday,
        mastery_level: wa.user.user_masteries.find_by(
          knowledge_node: wa.question.question_concepts.first&.knowledge_node
        )&.mastery_level || 0.0,
        label: determine_error_pattern_label(wa)
      }
    end
  end

  def gather_error_prediction_data
    ExamAnswer.joins(:question, :user)
              .includes(question: :question_concepts)
              .where('exam_answers.created_at > ?', 60.days.ago)
              .limit(500)
              .map do |answer|
      concept = answer.question.question_concepts.first&.knowledge_node
      mastery = answer.user.user_masteries.find_by(knowledge_node: concept)

      {
        answer_id: answer.id,
        mastery_level: mastery&.mastery_level || 0.0,
        previous_errors: answer.user.wrong_answers.where(question: answer.question).count,
        difficulty: answer.question.difficulty || 3,
        time_spent: answer.time_spent || 0,
        actual_result: answer.is_correct ? 'correct' : 'incorrect'
      }
    end
  end

  def gather_time_series_data
    # Daily error counts for all users over past 90 days
    (90.days.ago.to_date..Date.today).map do |date|
      error_count = WrongAnswer.where('DATE(last_attempted_at) = ?', date).count
      accuracy = calculate_daily_accuracy(date)
      session_count = ExamSession.where('DATE(created_at) = ?', date).count

      {
        date: date.to_s,
        error_count: error_count,
        accuracy: accuracy,
        session_count: session_count
      }
    end
  end

  def gather_normal_behavior_data
    ExamSession.where('created_at > ?', 60.days.ago)
               .where.not(completed_at: nil)
               .where('correct_answers > 0')
               .limit(500)
               .map do |session|
      {
        session_id: session.id,
        accuracy: (session.correct_answers.to_f / session.total_questions * 100).round(2),
        time_per_question: calculate_avg_time(session),
        completion_rate: (session.answered_questions.to_f / session.total_questions * 100).round(2),
        score: session.score || 0
      }
    end
  end

  # Prompt building methods
  def build_classification_training_prompt(training_data)
    <<~PROMPT
      Train a classification model to categorize error patterns.

      Training data (#{training_data.length} samples):
      #{training_data.take(100).to_json}

      Features:
      - difficulty: Question difficulty (1-5)
      - topic: Question topic
      - attempt_count: Number of attempts
      - time_of_day: Hour of day (0-23)
      - mastery_level: User mastery (0-1)

      Labels: careless, concept_gap, difficult_content, persistent_gap

      Build a classification model and return:
      - parameters: Model configuration
      - weights: Feature weights/importance
      - feature_importance: Importance scores for each feature
      - accuracy: Training accuracy (0-1)
      - precision: Precision score
      - recall: Recall score
      - f1_score: F1 score
      - confusion_matrix: Confusion matrix

      Return as JSON.
    PROMPT
  end

  def build_error_prediction_prompt(training_data)
    <<~PROMPT
      Train a predictive model to forecast whether a user will answer correctly.

      Training data (#{training_data.length} samples):
      #{training_data.take(50).to_json}

      Features:
      - mastery_level: Current mastery (0-1)
      - previous_errors: Count of previous errors
      - difficulty: Question difficulty (1-5)
      - time_spent: Time spent on question (seconds)

      Target: actual_result (correct/incorrect)

      Build a prediction model and return:
      - parameters: Model configuration
      - accuracy: Prediction accuracy
      - precision: Precision score
      - recall: Recall score

      Return as JSON.
    PROMPT
  end

  def build_time_series_prompt(time_series_data)
    <<~PROMPT
      Train an ARIMA time series model to forecast error trends.

      Time series data (#{time_series_data.length} days):
      #{time_series_data.to_json}

      Build a time series forecasting model and return:
      - parameters: Model parameters (p, d, q for ARIMA)
      - mae: Mean Absolute Error
      - rmse: Root Mean Squared Error
      - trend: Overall trend (increasing/decreasing/stable)

      Return as JSON.
    PROMPT
  end

  def build_anomaly_detection_prompt(normal_data)
    <<~PROMPT
      Train an anomaly detection model to identify unusual exam sessions.

      Normal behavior data (#{normal_data.length} sessions):
      #{normal_data.take(100).to_json}

      Features represent normal session behavior:
      - accuracy: Percent correct (0-100)
      - time_per_question: Average time (seconds)
      - completion_rate: Percent completed (0-100)
      - score: Overall score

      Build an anomaly detection model and return:
      - parameters: Threshold parameters
      - accuracy: Detection accuracy
      - precision: Precision for anomaly detection
      - recall: Recall for anomaly detection
      - normal_ranges: Expected ranges for each feature

      Return as JSON.
    PROMPT
  end

  # Helper methods
  def determine_error_pattern_label(wrong_answer)
    user = wrong_answer.user
    question = wrong_answer.question

    concept = question.question_concepts.first&.knowledge_node
    mastery = user.user_masteries.find_by(knowledge_node: concept)

    if mastery&.mastery_level.to_f > 0.7
      'careless'
    elsif wrong_answer.attempt_count.to_i > 2
      'persistent_gap'
    elsif question.difficulty.to_i > 4
      'difficult_content'
    else
      'concept_gap'
    end
  end

  def calculate_daily_accuracy(date)
    answers = ExamAnswer.where('DATE(created_at) = ?', date)
    return 0.0 if answers.count.zero?

    correct = answers.where(is_correct: true).count
    (correct.to_f / answers.count * 100).round(2)
  end

  def calculate_avg_time(session)
    session.exam_answers.average(:time_spent)&.to_i || 0
  end

  def extract_feature_names
    ['difficulty', 'topic', 'attempt_count', 'time_of_day', 'mastery_level']
  end
end
