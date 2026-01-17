# Epic 11: Performance Tracking - Quick Start Guide

## Immediate Next Steps

### 1. Apply Database Migrations
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
bundle exec rails db:migrate
```

This creates:
- `performance_snapshots` table
- Enhances `user_masteries` table

### 2. Test Basic API

**Quick Summary:**
```bash
curl -X GET "http://localhost:3000/api/v1/performance/quick_summary?study_set_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**Expected Response:**
```json
{
  "status": "success",
  "data": {
    "total_concepts": 150,
    "mastered": 45,
    "learning": 60,
    "weak": 30,
    "untested": 15,
    "overall_mastery": 0.672,
    "overall_accuracy": 73.5,
    "completion_rate": 90.0
  }
}
```

### 3. Generate First Snapshot
```bash
curl -X POST "http://localhost:3000/api/v1/performance/generate_snapshot?study_set_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. View Predictions
```bash
curl -X GET "http://localhost:3000/api/v1/performance/exam_score_prediction?study_set_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## API Endpoints by Use Case

### Dashboard Display
```
GET /api/v1/performance/quick_summary
GET /api/v1/performance/chart_data?chart_type=progress
GET /api/v1/performance/strengths_weaknesses?limit=5
```

### Detailed Analysis Page
```
GET /api/v1/performance/comprehensive_report
GET /api/v1/performance/subject_breakdown
GET /api/v1/performance/concept_analysis
```

### Time Analysis Page
```
GET /api/v1/performance/time_analysis
GET /api/v1/performance/time_of_day
GET /api/v1/performance/consistency
GET /api/v1/performance/chart_data?chart_type=heatmap
```

### Predictions Page
```
GET /api/v1/performance/predictions
GET /api/v1/performance/exam_score_prediction
GET /api/v1/performance/mastery_timeline?target_mastery=0.8
GET /api/v1/performance/goal_achievement?target_score=80
GET /api/v1/performance/risk_assessment
```

### History/Trends Page
```
GET /api/v1/performance/snapshots?start_date=2026-01-01
GET /api/v1/performance/daily_patterns
GET /api/v1/performance/weekly_patterns
GET /api/v1/performance/chart_data?chart_type=trend
```

---

## Chart.js Integration Examples

### 1. Mastery Trend Line Chart
```javascript
fetch('/api/v1/performance/chart_data?chart_type=trend&study_set_id=1')
  .then(res => res.json())
  .then(data => {
    new Chart(ctx, {
      type: 'line',
      data: data.data,
      options: {
        responsive: true,
        scales: {
          y: { beginAtZero: true, max: 1 }
        }
      }
    });
  });
```

### 2. Subject Performance Radar Chart
```javascript
fetch('/api/v1/performance/chart_data?chart_type=radar&study_set_id=1')
  .then(res => res.json())
  .then(data => {
    new Chart(ctx, {
      type: 'radar',
      data: data.data,
      options: {
        scales: {
          r: { beginAtZero: true, max: 1 }
        }
      }
    });
  });
```

### 3. Progress Pie Chart
```javascript
fetch('/api/v1/performance/chart_data?chart_type=progress&study_set_id=1')
  .then(res => res.json())
  .then(data => {
    new Chart(ctx, {
      type: 'doughnut',
      data: data.data,
      options: {
        responsive: true
      }
    });
  });
```

### 4. Time of Day Heatmap
```javascript
fetch('/api/v1/performance/chart_data?chart_type=heatmap&study_set_id=1')
  .then(res => res.json())
  .then(data => {
    // Use with Chart.js Matrix plugin or custom implementation
    new Chart(ctx, {
      type: 'matrix',
      data: data.data,
      options: {
        scales: {
          x: { type: 'category' },
          y: { type: 'category' }
        }
      }
    });
  });
```

---

## Background Job Setup

### Option 1: Manual Trigger
```ruby
# In Rails console
GeneratePerformanceSnapshotJob.perform_now(user.id, study_set_id: 1)
```

### Option 2: Scheduled (using whenever gem)
```ruby
# In config/schedule.rb
every 1.day, at: '11:59 PM' do
  runner "GeneratePerformanceSnapshotJob.generate_for_all_users"
end

# Deploy schedule
whenever --update-crontab
```

### Option 3: Solid Queue (Rails 8)
```ruby
# Generate snapshot every day at midnight
GeneratePerformanceSnapshotJob
  .set(wait_until: Date.tomorrow.midnight)
  .perform_later(user.id, study_set_id: study_set.id)
```

---

## Frontend Integration Example (React)

```jsx
import React, { useEffect, useState } from 'react';
import { Chart as ChartJS, registerables } from 'chart.js';
import { Line, Radar, Doughnut } from 'react-chartjs-2';

ChartJS.register(...registerables);

function PerformanceDashboard({ studySetId }) {
  const [summary, setSummary] = useState(null);
  const [trendData, setTrendData] = useState(null);
  const [predictions, setPredictions] = useState(null);

  useEffect(() => {
    // Fetch quick summary
    fetch(`/api/v1/performance/quick_summary?study_set_id=${studySetId}`)
      .then(res => res.json())
      .then(data => setSummary(data.data));

    // Fetch trend chart data
    fetch(`/api/v1/performance/chart_data?chart_type=trend&study_set_id=${studySetId}`)
      .then(res => res.json())
      .then(data => setTrendData(data.data));

    // Fetch predictions
    fetch(`/api/v1/performance/exam_score_prediction?study_set_id=${studySetId}`)
      .then(res => res.json())
      .then(data => setPredictions(data.data));
  }, [studySetId]);

  if (!summary) return <div>Loading...</div>;

  return (
    <div className="performance-dashboard">
      {/* Summary Cards */}
      <div className="summary-cards">
        <div className="card">
          <h3>Overall Mastery</h3>
          <p className="metric">{(summary.overall_mastery * 100).toFixed(1)}%</p>
        </div>
        <div className="card">
          <h3>Accuracy</h3>
          <p className="metric">{summary.overall_accuracy.toFixed(1)}%</p>
        </div>
        <div className="card">
          <h3>Completion</h3>
          <p className="metric">{summary.completion_rate.toFixed(1)}%</p>
        </div>
        <div className="card">
          <h3>Predicted Score</h3>
          <p className="metric">{predictions?.predicted_score.toFixed(1)}</p>
        </div>
      </div>

      {/* Charts */}
      <div className="charts">
        <div className="chart-container">
          <h3>Progress Over Time</h3>
          {trendData && <Line data={trendData} />}
        </div>
      </div>

      {/* Concept Breakdown */}
      <div className="concept-breakdown">
        <div className="status-bar">
          <div className="mastered" style={{width: `${summary.mastered}%`}}>
            Mastered: {summary.mastered}
          </div>
          <div className="learning" style={{width: `${summary.learning}%`}}>
            Learning: {summary.learning}
          </div>
          <div className="weak" style={{width: `${summary.weak}%`}}>
            Weak: {summary.weak}
          </div>
        </div>
      </div>
    </div>
  );
}

export default PerformanceDashboard;
```

---

## Testing Checklist

### Basic Functionality
- [ ] Run migrations successfully
- [ ] Create test user and study set
- [ ] Generate performance snapshot
- [ ] Fetch quick summary
- [ ] View comprehensive report

### Advanced Features
- [ ] Get time of day analysis
- [ ] Calculate exam predictions
- [ ] Assess risks
- [ ] Generate chart data
- [ ] Compare with others

### Background Jobs
- [ ] Execute job manually
- [ ] Schedule automatic jobs
- [ ] Check job logs
- [ ] Verify snapshot creation

---

## Common Issues & Solutions

### Issue 1: Migrations Fail
```bash
# Check current schema version
bundle exec rails db:version

# Rollback if needed
bundle exec rails db:rollback STEP=2

# Re-run migrations
bundle exec rails db:migrate
```

### Issue 2: No Data Returned
- Ensure user has UserMastery records
- Verify study_set has knowledge nodes
- Check user_masteries have history data
- Generate test data if needed

### Issue 3: Predictions Return "insufficient_data"
- User needs at least 7 days of history
- Ensure user_masteries are being updated
- Generate snapshots to build history

### Issue 4: Authentication Errors
- Check current_user implementation
- Verify authentication token/session
- Update authenticate_user! method if needed

---

## Sample Data Generation (for Testing)

```ruby
# In Rails console

# Create test user
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.name = 'Test User'
  u.password = 'password123'
end

# Get study set
study_set = StudySet.find(1)

# Generate sample masteries
study_set.study_materials.each do |material|
  material.knowledge_nodes.where(level: 'concept').limit(20).each do |node|
    mastery = UserMastery.find_or_create_by(
      user: user,
      knowledge_node: node
    )

    # Simulate learning over time
    10.times do |i|
      correct = rand > 0.3
      mastery.update_with_attempt(
        correct: correct,
        time_minutes: rand(5..15)
      )
      sleep(0.1)
    end
  end
end

# Generate snapshot
GeneratePerformanceSnapshotJob.perform_now(user.id, study_set_id: study_set.id)

# Test API
puts "User ID: #{user.id}"
puts "Study Set ID: #{study_set.id}"
puts "Test URL: http://localhost:3000/api/v1/performance/quick_summary?study_set_id=#{study_set.id}"
```

---

## Monitoring & Maintenance

### Key Metrics to Monitor
- API response times
- Background job success rate
- Database query performance
- Snapshot generation time
- User engagement with reports

### Maintenance Tasks
- Weekly: Review failed jobs
- Monthly: Archive old snapshots
- Quarterly: Optimize database indexes
- As needed: Add caching layers

---

## Support Resources

- **Full Documentation:** `PERFORMANCE_TRACKING_IMPLEMENTATION.md`
- **Completion Summary:** `EPIC_11_COMPLETION_SUMMARY.md`
- **This Guide:** `QUICK_START_GUIDE.md`

---

**Last Updated:** January 15, 2026
**Version:** 1.0.0
**Status:** Production Ready ✓
