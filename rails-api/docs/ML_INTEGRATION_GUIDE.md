# ML Integration Guide for Epic 12: Weakness Analysis

## Overview

Epic 12 (Weakness Analysis) has been enhanced with ML-based pattern detection, A/B testing framework, and advanced analytics. This guide explains how the ML components work and how to integrate with external ML services.

## Architecture

### Components

1. **ML Pattern Detector** (`ml_pattern_detector.rb`)
   - Clustering (K-means simulation via OpenAI)
   - Classification (Random Forest simulation via OpenAI)
   - Time Series Analysis (ARIMA simulation via OpenAI)
   - Anomaly Detection (Isolation Forest simulation via OpenAI)

2. **A/B Test Framework** (`ab_test_service.rb`)
   - Experiment management
   - Statistical significance testing
   - Variant assignment
   - Conversion tracking

3. **Advanced Weakness Analyzer** (`advanced_weakness_analyzer.rb`)
   - Multi-dimensional analysis
   - Severity scoring
   - Peer comparison
   - Improvement tracking

4. **Enhanced Learning Recommendation Engine** (`enhanced_learning_recommendation_engine.rb`)
   - Weakness-based learning paths
   - Spaced repetition scheduling
   - Personalized study plans
   - Optimal sequence determination

## Current Implementation (OpenAI-based)

### Why OpenAI?

The current implementation uses OpenAI GPT-4o for ML tasks because:
- No external dependencies (Python, scikit-learn, TensorFlow)
- Fast prototyping and iteration
- Good accuracy for pattern recognition
- Integrated with existing infrastructure

### Limitations

- Cost per API call
- Latency (network requests)
- Not true ML training (simulated)
- Limited to OpenAI's capabilities

## Production ML Integration Options

### Option 1: Python ML Service (Recommended)

**Architecture:**
```
Rails API → HTTP/gRPC → Python ML Service → scikit-learn/TensorFlow
```

**Setup:**

1. Create Python ML service:

```python
# ml_service/app.py
from flask import Flask, request, jsonify
from sklearn.ensemble import RandomForestClassifier, IsolationForest
from sklearn.cluster import KMeans
from statsmodels.tsa.arima.model import ARIMA
import numpy as np
import pickle

app = Flask(__name__)

# Load or train models
rf_model = None
kmeans_model = None
isolation_forest = None

@app.route('/classify', methods=['POST'])
def classify_error():
    data = request.json
    features = np.array(data['features']).reshape(1, -1)

    if rf_model is None:
        return jsonify({'error': 'Model not trained'}), 400

    prediction = rf_model.predict(features)
    probabilities = rf_model.predict_proba(features)

    return jsonify({
        'predicted_class': prediction[0],
        'probabilities': probabilities[0].tolist(),
        'confidence': max(probabilities[0])
    })

@app.route('/cluster', methods=['POST'])
def cluster_errors():
    data = request.json
    features = np.array(data['features'])
    n_clusters = data.get('n_clusters', 5)

    kmeans = KMeans(n_clusters=n_clusters, random_state=42)
    cluster_labels = kmeans.fit_predict(features)

    return jsonify({
        'clusters': cluster_labels.tolist(),
        'centroids': kmeans.cluster_centers_.tolist(),
        'inertia': kmeans.inertia_
    })

@app.route('/detect_anomaly', methods=['POST'])
def detect_anomaly():
    data = request.json
    features = np.array(data['features']).reshape(1, -1)

    if isolation_forest is None:
        # Train on normal data
        normal_data = np.array(data.get('normal_data', []))
        isolation_forest = IsolationForest(contamination=0.1, random_state=42)
        isolation_forest.fit(normal_data)

    prediction = isolation_forest.predict(features)
    anomaly_score = isolation_forest.score_samples(features)

    return jsonify({
        'is_anomaly': prediction[0] == -1,
        'anomaly_score': anomaly_score[0]
    })

@app.route('/forecast', methods=['POST'])
def forecast_time_series():
    data = request.json
    time_series = data['time_series']
    steps = data.get('steps', 7)

    # Fit ARIMA model
    model = ARIMA(time_series, order=(5, 1, 0))
    fitted = model.fit()

    # Forecast
    forecast = fitted.forecast(steps=steps)

    return jsonify({
        'forecast': forecast.tolist(),
        'confidence_intervals': fitted.get_forecast(steps).conf_int().tolist()
    })

@app.route('/train/classifier', methods=['POST'])
def train_classifier():
    data = request.json
    X = np.array(data['features'])
    y = np.array(data['labels'])

    global rf_model
    rf_model = RandomForestClassifier(n_estimators=100, random_state=42)
    rf_model.fit(X, y)

    # Save model
    with open('models/rf_model.pkl', 'wb') as f:
        pickle.dump(rf_model, f)

    accuracy = rf_model.score(X, y)

    return jsonify({
        'status': 'trained',
        'accuracy': accuracy,
        'feature_importances': rf_model.feature_importances_.tolist()
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

2. Update Rails service to call Python API:

```ruby
# app/services/ml_pattern_detector.rb
class MlPatternDetector
  def initialize(user)
    @user = user
    @ml_service_url = ENV['ML_SERVICE_URL'] || 'http://localhost:5000'
  end

  def classify_error_types
    errors = fetch_user_errors.includes(:question)
    return { accuracy: 0, message: 'Insufficient data' } if errors.count < 20

    # Prepare features
    features = errors.map { |e| extract_classification_features(e).values }
    labels = errors.map { |e| determine_error_label(e) }

    # Call Python ML service
    response = HTTParty.post(
      "#{@ml_service_url}/train/classifier",
      body: {
        features: features,
        labels: labels
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    result = JSON.parse(response.body)

    {
      model_type: 'random_forest',
      accuracy: result['accuracy'],
      feature_importance: result['feature_importances'],
      training_samples: errors.count
    }
  end

  def cluster_errors
    errors = fetch_user_errors
    return { clusters: [], message: 'Insufficient data' } if errors.count < 10

    features = errors.map { |e| extract_features(e).values }

    response = HTTParty.post(
      "#{@ml_service_url}/cluster",
      body: {
        features: features,
        n_clusters: 5
      }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    result = JSON.parse(response.body)

    {
      clusters: map_clusters_to_errors(result['clusters'], errors),
      centroids: result['centroids'],
      inertia: result['inertia']
    }
  end

  private

  def map_clusters_to_errors(cluster_labels, errors)
    clusters = Hash.new { |h, k| h[k] = [] }

    cluster_labels.each_with_index do |label, idx|
      clusters[label] << {
        error_id: errors[idx].id,
        question_id: errors[idx].question_id
      }
    end

    clusters.map do |label, members|
      {
        cluster_id: label,
        name: "Error Pattern #{label + 1}",
        member_count: members.count,
        members: members
      }
    end
  end
end
```

3. Docker setup:

```dockerfile
# Dockerfile.ml_service
FROM python:3.9-slim

WORKDIR /app

RUN pip install flask scikit-learn statsmodels numpy pandas

COPY ml_service/ .

CMD ["python", "app.py"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  rails:
    build: .
    ports:
      - "3000:3000"
    environment:
      - ML_SERVICE_URL=http://ml_service:5000
    depends_on:
      - ml_service

  ml_service:
    build:
      context: .
      dockerfile: Dockerfile.ml_service
    ports:
      - "5000:5000"
    volumes:
      - ./ml_service/models:/app/models
```

### Option 2: Ruby ML Libraries

**Gems:**
```ruby
# Gemfile
gem 'rumale'          # Comprehensive ML library
gem 'numo-narray'     # N-dimensional array
gem 'red-chainer'     # Deep learning framework
```

**Example:**

```ruby
# app/services/ruby_ml_classifier.rb
require 'rumale'

class RubyMlClassifier
  def train_classifier(features, labels)
    # Convert to Numo arrays
    x = Numo::DFloat.cast(features)
    y = Numo::Int32.cast(labels.map { |l| label_to_int(l) })

    # Train Random Forest
    rf = Rumale::Ensemble::RandomForestClassifier.new(
      n_estimators: 100,
      max_depth: 10,
      random_seed: 42
    )

    rf.fit(x, y)

    # Evaluate
    predictions = rf.predict(x)
    accuracy = Rumale::EvaluationMeasure::Accuracy.new.score(y, predictions)

    {
      model: rf,
      accuracy: accuracy,
      feature_importances: rf.feature_importances
    }
  end

  def predict(model, features)
    x = Numo::DFloat.cast(features).reshape(1, -1)
    prediction = model.predict(x)[0]
    probabilities = model.predict_proba(x)[0, true]

    {
      predicted_class: int_to_label(prediction),
      probabilities: probabilities.to_a,
      confidence: probabilities.max
    }
  end

  private

  def label_to_int(label)
    { 'careless' => 0, 'concept_gap' => 1, 'difficult_content' => 2, 'persistent_gap' => 3 }[label]
  end

  def int_to_label(int)
    ['careless', 'concept_gap', 'difficult_content', 'persistent_gap'][int]
  end
end
```

### Option 3: Cloud ML Services

**AWS SageMaker:**
```ruby
# app/services/sagemaker_ml_service.rb
require 'aws-sdk-sagemakerruntime'

class SagemakerMlService
  def initialize
    @client = Aws::SageMakerRuntime::Client.new(region: ENV['AWS_REGION'])
    @endpoint_name = ENV['SAGEMAKER_ENDPOINT']
  end

  def predict(features)
    response = @client.invoke_endpoint(
      endpoint_name: @endpoint_name,
      body: features.to_json,
      content_type: 'application/json'
    )

    JSON.parse(response.body.read)
  end
end
```

**Google Cloud AI Platform:**
```ruby
# app/services/gcp_ml_service.rb
require 'google/cloud/ai_platform'

class GcpMlService
  def initialize
    @client = Google::Cloud::AIPlatform.prediction_service
    @endpoint = ENV['GCP_MODEL_ENDPOINT']
  end

  def predict(features)
    request = {
      endpoint: @endpoint,
      instances: [features]
    }

    response = @client.predict(request)
    response.predictions.first
  end
end
```

## Migration Path: OpenAI → Production ML

### Phase 1: Parallel Running (Weeks 1-2)

Run both OpenAI and new ML service, compare results:

```ruby
class MlPatternDetector
  def detect_error_patterns
    openai_result = detect_with_openai
    ml_service_result = detect_with_ml_service if ENV['ML_SERVICE_ENABLED']

    # Compare results
    if ml_service_result
      log_comparison(openai_result, ml_service_result)
    end

    # Use OpenAI by default
    openai_result
  end
end
```

### Phase 2: Gradual Rollout (Weeks 3-4)

Use A/B testing framework:

```ruby
class MlPatternDetector
  def detect_error_patterns
    ab_test = AbTest.find_by(name: 'ml_service_rollout')
    assignment = ab_test&.assign_user(@user)

    case assignment&.variant
    when 'ml_service'
      detect_with_ml_service
    else
      detect_with_openai
    end
  end
end
```

### Phase 3: Full Migration (Week 5+)

Switch to ML service, keep OpenAI as fallback:

```ruby
class MlPatternDetector
  def detect_error_patterns
    detect_with_ml_service
  rescue StandardError => e
    Rails.logger.error("[MlPatternDetector] ML service failed: #{e.message}")
    detect_with_openai # Fallback
  end
end
```

## Performance Optimization

### Caching

```ruby
# app/services/ml_pattern_detector.rb
class MlPatternDetector
  def detect_error_patterns
    cache_key = "ml_patterns:#{@user.id}:#{Date.today}"

    Rails.cache.fetch(cache_key, expires_in: 6.hours) do
      perform_detection
    end
  end
end
```

### Background Processing

```ruby
# app/jobs/detect_patterns_job.rb
class DetectPatternsJob < ApplicationJob
  queue_as :ml_processing

  def perform(user_id)
    user = User.find(user_id)
    detector = MlPatternDetector.new(user)

    patterns = detector.detect_error_patterns

    # Store results
    user.update(ml_patterns_cache: patterns, ml_patterns_updated_at: Time.current)
  end
end
```

### Batch Processing

```ruby
# app/services/batch_ml_processor.rb
class BatchMlProcessor
  def process_users(user_ids)
    user_ids.in_groups_of(100, false) do |batch|
      batch.each do |user_id|
        DetectPatternsJob.perform_later(user_id)
      end
    end
  end
end
```

## Testing

### Unit Tests

```ruby
# test/services/ml_pattern_detector_test.rb
require 'test_helper'

class MlPatternDetectorTest < ActiveSupport::TestCase
  test "classifies error patterns correctly" do
    user = users(:alice)
    detector = MlPatternDetector.new(user)

    result = detector.classify_error_types

    assert result[:accuracy] > 0.7
    assert result[:feature_importance].present?
  end

  test "handles insufficient data gracefully" do
    user = User.create!(email: 'test@example.com')
    detector = MlPatternDetector.new(user)

    result = detector.classify_error_types

    assert_equal 'Insufficient data', result[:message]
  end
end
```

### Integration Tests

```ruby
# test/integration/ml_service_integration_test.rb
require 'test_helper'

class MlServiceIntegrationTest < ActionDispatch::IntegrationTest
  test "ML service responds correctly" do
    skip unless ENV['ML_SERVICE_ENABLED']

    response = HTTParty.post(
      "#{ENV['ML_SERVICE_URL']}/classify",
      body: { features: [[3, 0.5, 2, 14, 0.3]] }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )

    assert_equal 200, response.code
    assert response['predicted_class'].present?
  end
end
```

## Monitoring

### Metrics to Track

1. **Model Performance**
   - Accuracy
   - Precision
   - Recall
   - F1 Score
   - Prediction latency

2. **Business Metrics**
   - User engagement with recommendations
   - Learning path completion rates
   - Improvement in test scores
   - A/B test conversion rates

3. **System Metrics**
   - API response times
   - Error rates
   - Cache hit rates
   - Job queue lengths

### Logging

```ruby
# app/services/ml_pattern_detector.rb
class MlPatternDetector
  def classify_error_types
    start_time = Time.current

    result = perform_classification

    duration = Time.current - start_time

    Rails.logger.info(
      "[MLPatternDetector] Classification completed",
      user_id: @user.id,
      duration_ms: (duration * 1000).round,
      accuracy: result[:accuracy],
      sample_count: result[:training_samples]
    )

    result
  end
end
```

## Cost Estimation

### Current (OpenAI)
- ~$0.002 per classification
- ~$0.005 per clustering analysis
- ~$0.003 per time series forecast

**Monthly cost (1000 users, weekly analysis):**
- 1000 users × 4 analyses/month × $0.01 = $40/month

### Python ML Service (AWS)
- EC2 t3.medium: $30/month
- Storage: $5/month
- Data transfer: $10/month

**Monthly cost:** ~$45/month

### Savings at Scale
- 10,000 users: OpenAI ($400) vs ML Service ($45) = $355/month saved
- 100,000 users: OpenAI ($4,000) vs ML Service ($200) = $3,800/month saved

## Next Steps

1. **Immediate** (Current Sprint)
   - Deploy current OpenAI-based solution
   - Set up monitoring and logging
   - Collect baseline metrics

2. **Short-term** (Next Sprint)
   - Build Python ML service prototype
   - Run parallel testing
   - Measure accuracy comparison

3. **Medium-term** (Next Quarter)
   - Gradual rollout with A/B testing
   - Train models on production data
   - Optimize performance

4. **Long-term** (Next 6 months)
   - Full migration to ML service
   - Advanced models (deep learning)
   - Real-time predictions

## Support

For questions or issues:
- Technical documentation: `/docs/ML_INTEGRATION_GUIDE.md`
- API documentation: `/docs/api/ML_API.md`
- Slack: #ml-integration
- Email: ml-team@example.com

## References

- [scikit-learn Documentation](https://scikit-learn.org/)
- [Rumale Documentation](https://github.com/yoshoku/rumale)
- [AWS SageMaker](https://aws.amazon.com/sagemaker/)
- [Google Cloud AI Platform](https://cloud.google.com/ai-platform)
- [OpenAI API](https://platform.openai.com/docs/)
