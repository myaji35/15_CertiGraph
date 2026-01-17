# Epic 12: Weakness Analysis - Quick Start Guide

## Installation & Setup

### 1. Run Database Migrations

```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
rails db:migrate
```

**New tables created:**
- `ab_tests`
- `ab_test_assignments`
- `ml_models`
- `ml_predictions`
- `weakness_reports`

### 2. Verify Environment Variables

```bash
# .env
OPENAI_API_KEY=your_api_key_here
ML_SERVICE_URL=http://localhost:5000  # Optional, for future Python ML service
```

### 3. Restart Server

```bash
rails server
```

## Quick Examples

### Generate a Weakness Report (Most Common Use Case)

```ruby
# In Rails console or controller
user = User.find(1)
study_material = StudyMaterial.find(1)

# Create analyzer
analyzer = AdvancedWeaknessAnalyzer.new(user, study_material)

# Generate comprehensive report
report = analyzer.generate_report(report_type: 'comprehensive')

# Access results
puts "Weakness Score: #{report.overall_weakness_score}/100"
puts "Critical Issues: #{report.critical_weaknesses.count}"
puts "Improvement: #{report.improvement_percentage}%"
puts "Percentile: #{report.percentile_rank}%"
```

### API Call (from frontend)

```javascript
// POST /api/v1/weakness_reports
const response = await fetch('/api/v1/weakness_reports', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`
  },
  body: JSON.stringify({
    study_material_id: 1,
    report_type: 'comprehensive'
  })
});

const report = await response.json();
console.log('Weakness Score:', report.report.overall_weakness_score);
```

### Detect ML Patterns

```ruby
# Create detector
user = User.find(1)
detector = MlPatternDetector.new(user)

# Detect all patterns
patterns = detector.detect_error_patterns

# Access specific analyses
clusters = patterns[:clustering_patterns][:clusters]
classification = patterns[:classification_patterns]
forecast = patterns[:time_series_patterns][:forecast]
anomalies = patterns[:anomalies][:anomalies]

puts "Found #{clusters.count} error patterns"
puts "Detected #{anomalies.count} anomalies"
```

### Generate Enhanced Recommendations

```ruby
# Create recommendation engine
user = User.find(1)
study_material = StudyMaterial.find(1)
engine = EnhancedLearningRecommendationEngine.new(user, study_material)

# Generate all recommendations
recommendations = engine.generate_recommendations

# Access specific recommendations
learning_paths = recommendations[:learning_paths]
optimal_sequence = recommendations[:optimal_sequence]
spaced_repetition = recommendations[:spaced_repetition_schedule]
practice_questions = recommendations[:practice_questions]

# Show intensive path
intensive = learning_paths[:intensive_path]
puts "#{intensive[:name]}: #{intensive[:duration_weeks]} weeks"
puts "Daily commitment: #{intensive[:daily_commitment_hours]} hours"
```

### Run A/B Test

```ruby
# Create test
ab_test_service = AbTestService.new

# Use pre-built template
test_config = AbTestService.recommendation_algorithm_test(created_by: admin_user)
ab_test = ab_test_service.create_test(test_config)

# Or create custom test
ab_test = ab_test_service.create_test(
  name: 'Custom Test',
  test_type: 'ui',
  variants: {
    control: { layout: 'list' },
    treatment: { layout: 'grid' }
  },
  primary_metrics: ['engagement'],
  created_by: admin_user
)

# Start test
ab_test.start!

# Assign users (happens automatically when users access features)
assignment = ab_test_service.assign_user_to_test(ab_test.id, user)

# Track events
ab_test_service.track_event(ab_test.id, user, 'conversion', {
  accuracy_improvement: 12.5
})

# Analyze results
analysis = ab_test_service.analyze_results(ab_test.id)
puts "Winner: #{analysis[:winner]}" if analysis[:winner]
puts "Significant: #{analysis[:statistical_significance]}"
```

### Train ML Model

```ruby
# Create model
model = MlModel.create!(
  name: 'Error Classifier v2',
  model_type: 'pattern_classifier',
  algorithm: 'random_forest',
  version: '2.0',
  trained_by: User.find_by(role: 'admin')
)

# Train in background
TrainMlModelJob.perform_later(model.id)

# Or train immediately (for testing)
TrainMlModelJob.new.perform(model.id)

# Check status
model.reload
puts "Status: #{model.status}"
puts "Accuracy: #{model.accuracy * 100}%" if model.trained?

# Deploy model
model.deploy! if model.trained?

# Make prediction
prediction = model.predict(
  {
    difficulty: 4,
    mastery_level: 0.35,
    previous_errors: 3,
    time_of_day: 14
  },
  user: user,
  context: { prediction_type: 'error_pattern' }
)

puts "Predicted: #{prediction[:predicted_class]}"
puts "Confidence: #{prediction[:confidence] * 100}%"
```

## Common API Endpoints

### Weakness Reports

```bash
# Generate report
POST /api/v1/weakness_reports
{
  "study_material_id": 1,
  "report_type": "comprehensive"
}

# List reports
GET /api/v1/weakness_reports

# View specific report
GET /api/v1/weakness_reports/:id

# Generate PDF
POST /api/v1/weakness_reports/:id/generate_pdf

# Download PDF
GET /api/v1/weakness_reports/:id/download_pdf
```

### ML Patterns

```bash
# Detect all patterns
GET /api/v1/ml_patterns/detect

# Cluster errors
GET /api/v1/ml_patterns/cluster_errors

# Time series forecast
GET /api/v1/ml_patterns/time_series

# Detect anomalies
GET /api/v1/ml_patterns/anomalies

# Get predictions
GET /api/v1/ml_patterns/predictions
```

### Enhanced Recommendations

```bash
# Generate all recommendations
POST /api/v1/study_materials/:id/enhanced_recommendations/generate

# Get learning paths
GET /api/v1/study_materials/:id/enhanced_recommendations/learning_paths

# Get optimal sequence
GET /api/v1/study_materials/:id/enhanced_recommendations/optimal_sequence

# Get spaced repetition schedule
GET /api/v1/study_materials/:id/enhanced_recommendations/spaced_repetition_schedule

# Get practice questions
GET /api/v1/study_materials/:id/enhanced_recommendations/practice_questions

# Get review schedule
GET /api/v1/study_materials/:id/enhanced_recommendations/review_schedule

# Get personalization
GET /api/v1/study_materials/:id/enhanced_recommendations/personalization
```

### A/B Tests

```bash
# List tests
GET /api/v1/ab_tests

# Get test templates
GET /api/v1/ab_tests/templates

# Create test
POST /api/v1/ab_tests
{
  "ab_test": {
    "name": "Test Name",
    "test_type": "algorithm",
    "variants": { "control": {}, "treatment": {} },
    "primary_metrics": ["accuracy_improvement"]
  }
}

# Start test
POST /api/v1/ab_tests/:id/start

# Assign variant
POST /api/v1/ab_tests/:id/assign_variant

# Track event
POST /api/v1/ab_tests/:id/track_event
{
  "event_type": "conversion",
  "event_data": { "accuracy_improvement": 15 }
}

# Get results
GET /api/v1/ab_tests/:id/results

# Check early stopping
GET /api/v1/ab_tests/:id/early_stopping_check

# Complete test
POST /api/v1/ab_tests/:id/complete
```

### ML Models

```bash
# List models
GET /api/v1/ml_models?model_type=pattern_classifier

# Create model
POST /api/v1/ml_models
{
  "ml_model": {
    "name": "Classifier v1",
    "model_type": "pattern_classifier",
    "algorithm": "random_forest"
  }
}

# Train model
POST /api/v1/ml_models/:id/train

# Deploy model
POST /api/v1/ml_models/:id/deploy

# Make prediction
POST /api/v1/ml_models/:id/predict
{
  "input_features": {
    "difficulty": 4,
    "mastery_level": 0.5
  },
  "prediction_type": "error_pattern"
}

# Get metrics
GET /api/v1/ml_models/:id/metrics

# Create new version
POST /api/v1/ml_models/:id/create_version
```

## Testing

### Run Tests

```bash
# All tests
rails test

# Specific service tests
rails test test/services/ml_pattern_detector_test.rb
rails test test/services/ab_test_service_test.rb
rails test test/services/advanced_weakness_analyzer_test.rb

# Controller tests
rails test test/controllers/ab_tests_controller_test.rb
rails test test/controllers/ml_models_controller_test.rb
rails test test/controllers/weakness_reports_controller_test.rb
```

### Manual Testing in Console

```ruby
# Rails console
rails console

# Create test user with data
user = User.create!(email: 'test@example.com', name: 'Test User', password: 'password')

# Create study material
study_set = StudySet.create!(user: user, title: 'Test Set')
study_material = StudyMaterial.create!(study_set: study_set, name: 'Test Material')

# Create some wrong answers (for testing)
10.times do |i|
  question = Question.create!(
    study_material: study_material,
    content: "Question #{i}",
    difficulty: [1,2,3,4,5].sample,
    answer: '1'
  )

  WrongAnswer.create!(
    user: user,
    question: question,
    study_set: study_set,
    selected_answer: '2',
    attempt_count: [1,2,3].sample,
    last_attempted_at: rand(1..30).days.ago
  )
end

# Now test weakness analysis
analyzer = AdvancedWeaknessAnalyzer.new(user, study_material)
report = analyzer.generate_report
puts "Report generated with score: #{report.overall_weakness_score}"
```

## Troubleshooting

### Issue: ML Pattern Detection Returns Empty Results

**Solution:** Ensure user has at least 10 wrong answers
```ruby
user.wrong_answers.count # Should be >= 10
```

### Issue: A/B Test Assignment Fails

**Solution:** Check test status and user eligibility
```ruby
ab_test.status # Should be 'running'
ab_test.traffic_allocation # Should be > 0
```

### Issue: ML Model Training Fails

**Solution:** Check training data availability
```ruby
WrongAnswer.count # Should be >= 100 for pattern classifier
ExamAnswer.count # Should be >= 50 for error predictor
```

### Issue: Weakness Report Generation is Slow

**Solution:** Use background job processing
```ruby
# Instead of synchronous generation
GenerateWeaknessReportJob.perform_later(user.id, study_material.id)
```

### Issue: OpenAI API Rate Limit

**Solution:** Implement caching
```ruby
Rails.cache.fetch("ml_patterns:#{user.id}:#{Date.today}", expires_in: 6.hours) do
  detector.detect_error_patterns
end
```

## Performance Tips

1. **Cache ML Results**: 6-hour TTL recommended
2. **Use Background Jobs**: For training and report generation
3. **Batch Processing**: Process users in groups of 100
4. **Database Indices**: All added automatically via migrations
5. **Pagination**: Use `limit` and `offset` for large datasets

## Best Practices

### When to Generate Weakness Reports

- After each exam completion
- Weekly for active users
- Monthly for all users
- On-demand when requested

### When to Run ML Pattern Detection

- Daily for active users (cached)
- Weekly for inactive users
- After significant data changes
- Before generating recommendations

### When to Use A/B Testing

- New recommendation algorithms
- UI/UX changes
- Learning path strategies
- Feature experiments

### When to Train ML Models

- Initial deployment
- Monthly updates
- After 1000+ new samples
- When accuracy drops below 80%

## Need Help?

- **Documentation**: `/docs/ML_INTEGRATION_GUIDE.md`
- **Full Summary**: `/docs/EPIC12_COMPLETION_SUMMARY.md`
- **Code Examples**: See files in `app/services/`, `app/models/`, `app/controllers/`
- **Tests**: See files in `test/` directory

---

*Quick Start Guide - Epic 12: Weakness Analysis*
*Version: 1.0*
*Last Updated: 2026-01-15*
