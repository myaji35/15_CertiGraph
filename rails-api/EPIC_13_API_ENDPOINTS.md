# Epic 13: Smart Recommendations - API Endpoints Reference

## Total Endpoints: 35 (Requirement: 15+) ✅

## Collection Endpoints (23)

### Original Endpoints (7)
1. `POST /recommendations/generate` - Generate recommendations using default engine
2. `GET /recommendations/learning_path` - Get learning path for study set
3. `GET /recommendations/personalized` - Get personalized recommendations
4. `GET /recommendations/similar_users` - Find similar users
5. `GET /recommendations/trending` - Get trending questions
6. `GET /recommendations/next_steps` - Get suggested next steps
7. `POST /recommendations/batch_generate` - Batch generate for all study sets

### Algorithm-Specific Generation (5)
8. `POST /recommendations/cf_generate` - Collaborative filtering recommendations
9. `POST /recommendations/cb_generate` - Content-based filtering recommendations
10. `POST /recommendations/hybrid_generate` - Hybrid (CF + CB) recommendations
11. `POST /recommendations/ensemble_generate` - Ensemble multi-strategy recommendations
12. `POST /recommendations/adaptive_generate` - Adaptive recommendations with auto-weights

### Learning Path Optimization (4)
13. `GET /recommendations/optimal_path` - Generate optimal learning sequence
14. `GET /recommendations/prioritized_concepts` - Get prioritized concept list
15. `POST /recommendations/study_schedule` - Generate personalized study schedule
16. `GET /recommendations/next_concept` - Get next best concept to study

### Metrics & Analytics (4)
17. `GET /recommendations/top_performing` - Get top performing recommendations
18. `GET /recommendations/algorithm_comparison` - Compare algorithm performance
19. `GET /recommendations/user_engagement` - Get user engagement metrics
20. `GET /recommendations/daily_report` - Get daily metrics report

### User Similarity (2)
21. `GET /recommendations/similarity_scores` - Get user similarity scores
22. `POST /recommendations/calculate_similarities` - Calculate user similarities

### Async Processing (1)
23. `POST /recommendations/batch_generate_async` - Async recommendation generation

## Member Endpoints (12)

### Core Actions (3)
1. `POST /recommendations/:id/accept` - Accept a recommendation
2. `POST /recommendations/:id/complete` - Mark recommendation as completed
3. `POST /recommendations/:id/dismiss` - Dismiss a recommendation

### Tracking & Metrics (6)
4. `POST /recommendations/:id/track_impression` - Track recommendation view
5. `POST /recommendations/:id/track_click` - Track recommendation click
6. `POST /recommendations/:id/track_completion` - Track recommendation completion
7. `POST /recommendations/:id/track_dismissal` - Track recommendation dismissal
8. `POST /recommendations/:id/rate` - Rate recommendation (1-5 stars)
9. `GET /recommendations/:id/metrics` - Get recommendation metrics

### Standard REST (2)
10. `GET /recommendations/:id` - Get single recommendation
11. `GET /recommendations` - List all recommendations (with filters)

## API Usage Examples

### 1. Generate Collaborative Filtering Recommendations
```bash
curl -X POST http://localhost:3000/recommendations/cf_generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "study_set_id": 1,
    "limit": 10
  }'
```

### 2. Generate Hybrid Recommendations with Custom Weights
```bash
curl -X POST http://localhost:3000/recommendations/hybrid_generate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "study_set_id": 1,
    "limit": 10,
    "cf_weight": 0.7,
    "cb_weight": 0.3
  }'
```

### 3. Get Optimal Learning Path
```bash
curl -X GET "http://localhost:3000/recommendations/optimal_path?study_set_id=1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 4. Generate Study Schedule
```bash
curl -X POST http://localhost:3000/recommendations/study_schedule \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "study_set_id": 1,
    "available_hours_per_day": 3,
    "target_date": "2026-02-15",
    "preferred_session_length": 2
  }'
```

### 5. Get Prioritized Concepts
```bash
curl -X GET "http://localhost:3000/recommendations/prioritized_concepts?study_set_id=1&exam_date=2026-03-01" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 6. Track Recommendation Click
```bash
curl -X POST http://localhost:3000/recommendations/1/track_click \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 7. Rate Recommendation
```bash
curl -X POST http://localhost:3000/recommendations/1/rate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "comment": "Very helpful recommendations!"
  }'
```

### 8. Get Recommendation Metrics
```bash
curl -X GET "http://localhost:3000/recommendations/1/metrics?period=30" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 9. Compare Algorithm Performance
```bash
curl -X GET "http://localhost:3000/recommendations/algorithm_comparison?period=30" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 10. Get User Engagement Metrics
```bash
curl -X GET "http://localhost:3000/recommendations/user_engagement?period=30" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 11. Find Similar Users
```bash
curl -X GET "http://localhost:3000/recommendations/similarity_scores?limit=10&min_similarity=70" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 12. Async Generate Recommendations
```bash
curl -X POST http://localhost:3000/recommendations/batch_generate_async \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "study_set_id": 1,
    "algorithm": "ensemble",
    "limit": 20
  }'
```

## Response Formats

### Success Response
```json
{
  "success": true,
  "recommendations": [...],
  "count": 10
}
```

### Error Response
```json
{
  "error": "Study set not found"
}
```

### Metrics Response
```json
{
  "success": true,
  "metrics": {
    "period_days": 7,
    "impressions": 150,
    "clicks": 45,
    "completions": 30,
    "ctr": 30.0,
    "completion_rate": 66.67,
    "avg_rating": 4.2
  },
  "quality": {
    "quality_score": 78.5,
    "grade": "B"
  }
}
```

## Query Parameters

### Common Parameters
- `study_set_id` (required for most endpoints) - ID of the study set
- `limit` (default: 10) - Number of recommendations to return
- `period` (default: 7) - Number of days for metrics

### Algorithm-Specific Parameters
- `cf_weight` (default: 0.6) - Weight for collaborative filtering
- `cb_weight` (default: 0.4) - Weight for content-based filtering
- `min_similarity` (default: 60.0) - Minimum similarity score for users
- `exam_date` - Target exam date for urgency calculation
- `available_hours_per_day` - Hours available per day for study
- `target_date` - Target completion date
- `preferred_session_length` - Preferred study session length in hours

## Features by Endpoint Category

### Collaborative Filtering
- User-based CF
- Item-based CF
- Hybrid CF
- Cosine similarity
- Similar user discovery

### Content-Based Filtering
- Concept matching
- Weakness targeting
- Progressive learning
- Diversity filtering

### Hybrid System
- Configurable weights
- Adaptive adjustment
- Ensemble strategies
- Context awareness

### Learning Path
- Dependency analysis
- Priority scoring
- Schedule generation
- Feasibility assessment

### Metrics & Tracking
- CTR tracking
- Completion rate
- Rating system
- Quality scoring
- Performance comparison
