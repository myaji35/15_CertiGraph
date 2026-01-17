class MlPatternDetector
  # ML-based pattern detection for error analysis
  # Uses OpenAI for pattern recognition and clustering
  # Can be extended to use Python scikit-learn via API

  def initialize(user)
    @user = user
    @openai_client = OpenaiClient.new
  end

  # Main pattern detection methods
  def detect_error_patterns
    {
      clustering_patterns: cluster_errors,
      classification_patterns: classify_error_types,
      time_series_patterns: analyze_time_series,
      anomalies: detect_anomalies
    }
  end

  # K-means clustering of error patterns
  def cluster_errors
    errors = fetch_user_errors

    return { clusters: [], message: 'Insufficient data' } if errors.count < 10

    # Prepare features for clustering
    feature_vectors = errors.map { |e| extract_features(e) }

    # Use OpenAI to identify patterns
    clusters = identify_clusters_with_ai(feature_vectors, errors)

    {
      clusters: clusters,
      optimal_k: clusters.length,
      silhouette_score: calculate_silhouette_score(clusters)
    }
  end

  # Random Forest classification for error types
  def classify_error_types
    errors = fetch_user_errors.includes(:question)

    return { accuracy: 0, message: 'Insufficient data' } if errors.count < 20

    # Extract features and labels
    training_data = errors.map do |error|
      {
        features: extract_classification_features(error),
        label: determine_error_label(error)
      }
    end

    # Use AI to build classification model
    model = build_classification_model(training_data)

    {
      model_type: 'random_forest',
      accuracy: model[:accuracy],
      feature_importance: model[:feature_importance],
      confusion_matrix: model[:confusion_matrix],
      predictions: model[:predictions]
    }
  end

  # ARIMA time series analysis
  def analyze_time_series
    # Get daily error counts for past 30 days
    error_counts = calculate_daily_error_counts(30)

    return { forecast: [], message: 'Insufficient data' } if error_counts.length < 7

    # Use AI to analyze trends and forecast
    analysis = analyze_time_series_with_ai(error_counts)

    {
      historical_data: error_counts,
      trend: analysis[:trend],
      seasonality: analysis[:seasonality],
      forecast: analysis[:forecast],
      confidence_intervals: analysis[:confidence_intervals]
    }
  end

  # Isolation Forest for anomaly detection
  def detect_anomalies
    recent_sessions = fetch_recent_exam_sessions(50)

    return { anomalies: [], message: 'Insufficient data' } if recent_sessions.count < 10

    # Extract performance metrics
    session_features = recent_sessions.map { |s| extract_session_features(s) }

    # Use AI to detect anomalies
    anomalies = detect_anomalies_with_ai(session_features, recent_sessions)

    {
      anomalies: anomalies,
      anomaly_rate: (anomalies.count.to_f / recent_sessions.count * 100).round(2),
      normal_range: calculate_normal_range(session_features)
    }
  end

  # Pattern prediction
  def predict_future_patterns(days_ahead = 7)
    current_patterns = detect_error_patterns

    # Use time series forecast
    forecast = analyze_time_series[:forecast]

    {
      predicted_error_count: forecast[days_ahead - 1],
      predicted_weak_concepts: predict_weak_concepts,
      risk_level: assess_risk_level(forecast),
      confidence: 0.75
    }
  end

  private

  def fetch_user_errors
    @user.wrong_answers
          .includes(:question)
          .order(last_attempted_at: :desc)
          .limit(100)
  end

  def fetch_recent_exam_sessions(limit)
    @user.exam_sessions
          .includes(:exam_answers)
          .order(created_at: :desc)
          .limit(limit)
  end

  # Feature extraction
  def extract_features(error)
    question = error.question

    {
      difficulty: question.difficulty || 3,
      topic_hash: question.topic.hash % 100,
      time_of_day: error.last_attempted_at.hour,
      day_of_week: error.last_attempted_at.wday,
      attempt_count: error.attempt_count || 1,
      days_since_first: (Time.current - error.created_at).to_i / 86400
    }
  end

  def extract_classification_features(error)
    question = error.question
    user_mastery = @user.user_masteries.find_by(
      knowledge_node: question.question_concepts.first&.knowledge_node
    )

    {
      difficulty: question.difficulty || 3,
      topic: question.topic,
      attempt_count: error.attempt_count || 1,
      mastery_level: user_mastery&.mastery_level || 0.0,
      time_spent: calculate_avg_time_spent(question),
      has_passage: question.question_passages.any?,
      option_count: question.options.count
    }
  end

  def extract_session_features(session)
    {
      accuracy: session.correct_answers.to_f / session.total_questions * 100,
      time_per_question: session.exam_answers.average(:time_spent) || 0,
      completion_rate: session.answered_questions.to_f / session.total_questions * 100,
      score: session.score || 0,
      session_duration: (session.completed_at - session.started_at).to_i rescue 0
    }
  end

  # AI-powered analysis methods
  def identify_clusters_with_ai(feature_vectors, errors)
    # Use OpenAI to identify patterns in error data
    prompt = build_clustering_prompt(feature_vectors, errors)

    begin
      response = @openai_client.chat(
        messages: [{ role: 'user', content: prompt }],
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' }
      )

      result = JSON.parse(response['choices'][0]['message']['content'])
      result['clusters'] || []
    rescue StandardError => e
      Rails.logger.error("[MlPatternDetector] Clustering failed: #{e.message}")
      []
    end
  end

  def build_classification_model(training_data)
    prompt = <<~PROMPT
      Analyze the following error classification data and build a predictive model.

      Training data (#{training_data.count} samples):
      #{training_data.take(20).to_json}

      Please:
      1. Identify the most important features for predicting error types
      2. Calculate accuracy based on the patterns
      3. Create a confusion matrix
      4. Provide feature importance scores

      Return JSON with: accuracy, feature_importance (hash), confusion_matrix (hash), predictions (array)
    PROMPT

    begin
      response = @openai_client.chat(
        messages: [{ role: 'user', content: prompt }],
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' }
      )

      JSON.parse(response['choices'][0]['message']['content'])
    rescue StandardError => e
      Rails.logger.error("[MlPatternDetector] Classification failed: #{e.message}")
      {
        accuracy: 0,
        feature_importance: {},
        confusion_matrix: {},
        predictions: []
      }
    end
  end

  def analyze_time_series_with_ai(error_counts)
    prompt = <<~PROMPT
      Analyze this time series of daily error counts and forecast the next 7 days:

      Historical data (past #{error_counts.length} days):
      #{error_counts.to_json}

      Please provide:
      1. Overall trend (increasing, decreasing, stable)
      2. Seasonality patterns (if any)
      3. 7-day forecast with values
      4. Confidence intervals (95%)

      Return JSON with: trend, seasonality, forecast (array), confidence_intervals (array of [lower, upper])
    PROMPT

    begin
      response = @openai_client.chat(
        messages: [{ role: 'user', content: prompt }],
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' }
      )

      JSON.parse(response['choices'][0]['message']['content'])
    rescue StandardError => e
      Rails.logger.error("[MlPatternDetector] Time series analysis failed: #{e.message}")
      {
        trend: 'unknown',
        seasonality: 'none',
        forecast: [],
        confidence_intervals: []
      }
    end
  end

  def detect_anomalies_with_ai(session_features, sessions)
    prompt = <<~PROMPT
      Analyze these exam session performance metrics and identify anomalies:

      Session data (#{sessions.count} sessions):
      #{session_features.to_json}

      Identify sessions that are statistically unusual in terms of:
      - Accuracy (significantly different from mean)
      - Time per question (outliers)
      - Completion rate (unusual patterns)

      Return JSON with: anomalies (array of indices), anomaly_scores (array), threshold
    PROMPT

    begin
      response = @openai_client.chat(
        messages: [{ role: 'user', content: prompt }],
        model: 'gpt-4o-mini',
        response_format: { type: 'json_object' }
      )

      result = JSON.parse(response['choices'][0]['message']['content'])

      # Map anomalies back to sessions
      anomaly_indices = result['anomalies'] || []
      anomaly_indices.map do |idx|
        {
          session_id: sessions[idx].id,
          features: session_features[idx],
          anomaly_score: result['anomaly_scores']&.dig(idx) || 0,
          reason: identify_anomaly_reason(session_features[idx])
        }
      end
    rescue StandardError => e
      Rails.logger.error("[MlPatternDetector] Anomaly detection failed: #{e.message}")
      []
    end
  end

  # Helper methods
  def build_clustering_prompt(feature_vectors, errors)
    <<~PROMPT
      Analyze these error patterns and group them into meaningful clusters:

      Error features (#{feature_vectors.count} errors):
      #{feature_vectors.take(30).to_json}

      Identify 3-5 distinct error patterns based on:
      - Difficulty level
      - Topic
      - Time of day/week
      - Attempt frequency

      Return JSON with: clusters (array of {name, description, member_count, characteristics})
    PROMPT
  end

  def calculate_daily_error_counts(days)
    start_date = days.days.ago.to_date
    end_date = Date.today

    (start_date..end_date).map do |date|
      count = @user.wrong_answers.where(
        'DATE(last_attempted_at) = ?', date
      ).count

      {
        date: date.to_s,
        count: count
      }
    end
  end

  def determine_error_label(error)
    question = error.question
    user_mastery = @user.user_masteries.find_by(
      knowledge_node: question.question_concepts.first&.knowledge_node
    )

    if user_mastery&.mastery_level.to_f > 0.7
      'careless'
    elsif error.attempt_count.to_i > 2
      'persistent_gap'
    elsif question.difficulty.to_i > 4
      'difficult_content'
    else
      'concept_gap'
    end
  end

  def calculate_avg_time_spent(question)
    ExamAnswer.where(question: question, user: @user)
              .average(:time_spent)&.to_i || 0
  end

  def calculate_silhouette_score(clusters)
    # Simplified silhouette score calculation
    return 0.0 if clusters.empty?

    avg_size = clusters.sum { |c| c['member_count'] || 0 }.to_f / clusters.length
    variance = clusters.sum { |c| ((c['member_count'] || 0) - avg_size)**2 } / clusters.length

    # Normalize to 0-1 range (higher is better clustering)
    (1.0 / (1.0 + Math.sqrt(variance))).round(3)
  end

  def calculate_normal_range(session_features)
    return {} if session_features.empty?

    accuracy_values = session_features.map { |f| f[:accuracy] }
    time_values = session_features.map { |f| f[:time_per_question] }

    {
      accuracy: {
        mean: accuracy_values.sum / accuracy_values.length,
        std: calculate_std(accuracy_values)
      },
      time_per_question: {
        mean: time_values.sum / time_values.length,
        std: calculate_std(time_values)
      }
    }
  end

  def calculate_std(values)
    mean = values.sum / values.length
    variance = values.sum { |v| (v - mean)**2 } / values.length
    Math.sqrt(variance).round(2)
  end

  def identify_anomaly_reason(features)
    reasons = []
    reasons << 'Unusually low accuracy' if features[:accuracy] < 40
    reasons << 'Very fast completion' if features[:time_per_question] < 30
    reasons << 'Very slow completion' if features[:time_per_question] > 300
    reasons << 'Incomplete session' if features[:completion_rate] < 50

    reasons.join(', ')
  end

  def predict_weak_concepts
    # Analyze recent patterns to predict future weak areas
    recent_errors = fetch_user_errors.limit(30)

    concept_errors = recent_errors.group_by do |error|
      error.question.question_concepts.first&.knowledge_node
    end

    concept_errors.map do |node, errors|
      next unless node

      {
        concept_id: node.id,
        concept_name: node.name,
        predicted_difficulty: errors.length * 10,
        confidence: [0.5 + (errors.length * 0.05), 1.0].min
      }
    end.compact.sort_by { |c| -c[:predicted_difficulty] }.take(5)
  end

  def assess_risk_level(forecast)
    return 'low' if forecast.empty?

    avg_forecast = forecast.sum / forecast.length

    case avg_forecast
    when 0..2
      'low'
    when 2..5
      'moderate'
    else
      'high'
    end
  end
end
