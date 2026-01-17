# Answer Randomization - Quick Start Guide

## 5-Minute Integration Guide

### Basic Usage

#### 1. Enable Randomization for an Exam

```ruby
# When creating an exam session
exam_session = ExamSession.create!(
  study_set: study_set,
  user: current_user,
  exam_type: 'mock_exam',
  status: 'in_progress'
)

# Enable randomization (default: full_random strategy)
exam_session.initialize_randomization!

# Or with specific strategy
exam_session.initialize_randomization!(
  strategy: 'constrained_random',
  enabled: true
)
```

#### 2. Get Randomized Questions

```ruby
# Randomize all questions
randomizations = exam_session.randomize_all_questions

# Each randomization contains:
# - question_id
# - randomized_options (shuffled)
# - option_map (for restoration)
# - original_correct_index
# - new_correct_index
# - seed
```

#### 3. Display Randomized Options

```ruby
randomizations.each do |item|
  question = Question.find(item[:question_id])
  randomized = item[:randomization][:randomized_options]

  randomized.each_with_index do |option, index|
    puts "#{index + 1}. #{option[:content]}"
  end
end
```

#### 4. Review Mode (Same Order)

```ruby
# For review, use same session - same seed = same order
review_session = ExamSession.find(original_exam_session_id)
if review_session.randomization_configured?
  # Will show same randomization as original
  same_randomization = review_session.randomize_question(question)
end
```

---

## API Endpoints Cheat Sheet

### Randomize Single Question
```bash
POST /api/v1/randomization/randomize_question
{
  "question_id": 123,
  "strategy": "full_random",
  "seed": "optional_seed_for_reproducibility"
}
```

### Randomize Entire Exam
```bash
POST /api/v1/randomization/randomize_exam
{
  "exam_session_id": 456,
  "strategy": "constrained_random"
}
```

### Toggle Randomization
```bash
PUT /api/v1/randomization/toggle/456
# Toggles enabled/disabled
```

### Set Strategy
```bash
PUT /api/v1/randomization/set_strategy/456
{
  "strategy": "block_random"
}
```

### Analyze Quality
```bash
POST /api/v1/randomization/analyze/789
{
  "iterations": 100,
  "save_results": true
}
```

### Get Quality Report
```bash
GET /api/v1/randomization/report/789
```

---

## Strategies Explained

### 1. Full Random (Default)
```ruby
strategy: 'full_random'
```
- **Algorithm**: Fisher-Yates shuffle
- **Bias**: None (perfectly unbiased)
- **Use Case**: Standard exams, general purpose
- **Uniformity**: 99%+

### 2. Constrained Random
```ruby
strategy: 'constrained_random'
```
- **Algorithm**: Fisher-Yates with position constraints
- **Bias**: Favors middle positions (1, 2, 3) for correct answer
- **Use Case**: Prevent pattern recognition, reduce edge clustering
- **Uniformity**: 95%+ (slight intentional bias)

### 3. Block Random
```ruby
strategy: 'block_random'
```
- **Algorithm**: Block-based shuffling
- **Bias**: None within blocks
- **Use Case**: Structured randomization, grouped questions
- **Uniformity**: 98%+

---

## Common Scenarios

### Scenario 1: New Mock Exam

```ruby
def create_mock_exam
  exam = ExamSession.create!(
    study_set: @study_set,
    user: current_user,
    exam_type: 'mock_exam',
    status: 'in_progress',
    started_at: Time.current
  )

  # Enable randomization
  exam.initialize_randomization!(strategy: 'constrained_random')

  # Get randomized questions
  @randomizations = exam.randomize_all_questions

  render json: {
    exam_id: exam.id,
    seed: exam.randomization_seed,
    questions: format_questions(@randomizations)
  }
end
```

### Scenario 2: Review Previous Exam

```ruby
def review_exam
  original_exam = ExamSession.find(params[:id])

  # Use same seed for review
  if original_exam.randomization_configured?
    @randomizations = original_exam.randomize_all_questions

    render json: {
      message: "Showing same order as original exam",
      seed: original_exam.randomization_seed,
      questions: format_questions(@randomizations)
    }
  end
end
```

### Scenario 3: Quality Check

```ruby
def check_randomization_quality
  study_material = StudyMaterial.find(params[:id])

  # Queue background analysis
  job = AnalyzeRandomizationJob.perform_later(
    study_material.id,
    100 # iterations
  )

  render json: {
    message: "Analysis queued",
    job_id: job.job_id
  }
end

def view_quality_report
  study_material = StudyMaterial.find(params[:id])
  analyzer = RandomizationAnalyzer.new(study_material)
  report = analyzer.generate_report

  render json: report
end
```

### Scenario 4: User Preference

```ruby
def update_randomization_settings
  exam = ExamSession.find(params[:id])

  case params[:action_type]
  when 'toggle'
    if exam.randomization_enabled?
      exam.disable_randomization!
    else
      exam.enable_randomization!
    end
  when 'change_strategy'
    exam.change_strategy!(params[:strategy])
  end

  render json: exam.randomization_summary
end
```

---

## Testing

### Test Uniformity

```ruby
# In Rails console
randomizer = AnswerRandomizer.new(strategy: 'full_random')
position_counts = randomizer.test_uniformity(iterations: 1000, num_options: 5)

# Check distribution
position_counts.each_with_index do |counts, position|
  puts "Position #{position}: #{counts}"
end
```

### Test Reproducibility

```ruby
seed = "test_seed_123"
randomizer1 = AnswerRandomizer.from_seed(seed)
randomizer2 = AnswerRandomizer.from_seed(seed)

result1 = randomizer1.randomize_question_options(question)
result2 = randomizer2.randomize_question_options(question)

# Should be identical
result1[:randomized_options] == result2[:randomized_options] # => true
```

### Analyze Quality

```ruby
analyzer = RandomizationAnalyzer.new(study_material)
analysis = analyzer.analyze_all_questions(iterations: 100)

puts "Overall Bias Score: #{analysis[:overall_bias_score]}"
puts "Uniformity Rate: #{(analysis[:uniformity_rate] * 100).round(1)}%"
puts "Quality: #{analysis[:quality_rating]}"

# Save results
analyzer.save_analysis_results(analysis)
```

---

## Configuration

### Default Settings

```ruby
# In exam_session.rb
RANDOMIZATION_STRATEGIES = %w[full_random constrained_random block_random]

# Default values
randomization_strategy: 'full_random'
randomization_enabled: true
```

### Change Defaults

```ruby
# In initializer or model
ExamSession::DEFAULT_STRATEGY = 'constrained_random'
```

---

## Performance Tips

### 1. Cache Randomizer
```ruby
# Good - cached
exam.randomizer.randomize_question_options(question)

# Bad - creates new instance
AnswerRandomizer.new(seed: exam.randomization_seed)
  .randomize_question_options(question)
```

### 2. Background Jobs for Analysis
```ruby
# For large materials (>50 questions)
AnalyzeRandomizationJob.perform_later(study_material.id, 100)

# For small materials (<50 questions)
analyzer = RandomizationAnalyzer.new(study_material)
analyzer.analyze_all_questions(iterations: 100)
```

### 3. Limit Iterations
```ruby
# Development: 50-100 iterations
analysis = analyzer.analyze_all_questions(iterations: 50)

# Production: 100-200 iterations
analysis = analyzer.analyze_all_questions(iterations: 100)

# Research: 1000+ iterations
analysis = analyzer.analyze_all_questions(iterations: 1000)
```

---

## Troubleshooting

### Issue: Randomization not working

```ruby
# Check if enabled
exam.randomization_enabled? # => should be true

# Check if seed exists
exam.randomization_seed # => should not be nil

# Check if strategy is valid
ExamSession::RANDOMIZATION_STRATEGIES.include?(exam.randomization_strategy)
# => should be true
```

### Issue: Same order every time

```ruby
# This is expected! Same seed = same order
# To get different order, generate new seed:
exam.randomization_seed = AnswerRandomizer.generate_seed
exam.save!
```

### Issue: Analysis taking too long

```ruby
# Use background job
AnalyzeRandomizationJob.perform_later(study_material.id, 100)

# Or reduce iterations
analyzer.analyze_all_questions(iterations: 50)
```

### Issue: High bias score

```ruby
# Check statistics
stats = RandomizationStat.by_material(study_material.id)
                         .biased # bias_score > 20

stats.each do |stat|
  puts "Question #{stat.question_id}: Bias = #{stat.bias_score}"
  puts stat.distribution_summary
end

# Try different strategy
exam.change_strategy!('full_random')
```

---

## Migration Checklist

- [ ] Run migrations: `bin/rails db:migrate`
- [ ] Verify schema: `bin/rails db:schema:dump`
- [ ] Run tests: `bin/rails test`
- [ ] Check routes: `bin/rails routes | grep randomization`
- [ ] Run verification: `ruby scripts/verify_epic10_implementation.rb`
- [ ] Test in console: Create exam and randomize
- [ ] Test API: Send POST request to `/api/v1/randomization/randomize_exam`
- [ ] Check logs: No errors
- [ ] Monitor jobs: Background analysis works
- [ ] Review quality: Check bias scores

---

## Quick Reference

### Model Methods

```ruby
# ExamSession
exam.initialize_randomization!(strategy:, enabled:)
exam.randomizer
exam.randomize_question(question)
exam.randomize_all_questions
exam.enable_randomization!(strategy: nil)
exam.disable_randomization!
exam.change_strategy!(new_strategy)
exam.randomization_summary
```

### Service Methods

```ruby
# AnswerRandomizer
randomizer = AnswerRandomizer.new(strategy:, seed:)
randomizer.randomize_question_options(question)
randomizer.randomize_exam_questions(questions)
randomizer.restore_original_order(options, map)
AnswerRandomizer.generate_seed
AnswerRandomizer.from_seed(seed, strategy:)

# RandomizationAnalyzer
analyzer = RandomizationAnalyzer.new(study_material)
analyzer.analyze_all_questions(iterations:)
analyzer.analyze_question(question, iterations:)
analyzer.generate_report
analyzer.save_analysis_results(analysis)
```

### Stats Methods

```ruby
# RandomizationStat
stat.position_count(position)
stat.quality_rating
stat.distribution_summary
stat.significantly_biased?
stat.most_frequent_position
stat.coefficient_of_variation
```

---

## Need Help?

1. Check full documentation: `docs/epic-10-randomization-complete.md`
2. Run verification: `ruby scripts/verify_epic10_implementation.rb`
3. Check tests: `test/services/answer_randomizer_test.rb`
4. View API docs: This file (RANDOMIZATION_QUICK_START.md)

---

**Last Updated**: January 15, 2026
**Version**: 1.0
**Status**: Production Ready
