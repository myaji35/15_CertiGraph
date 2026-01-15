# GraphRAG Analysis System - Comprehensive Test Scenarios

## Overview
This document describes comprehensive test scenarios for the GraphRAG analysis system (Epic 2, Phase 2).

## Test Environment Setup
- **Database**: SQLite3 with test data
- **API Endpoint**: `/api/v1/graph_rag/`
- **Authentication**: JWT token required
- **Response Format**: JSON

---

## 1. GraphRAG Analysis Service Tests

### Test Suite 1.1: Basic Analysis Flow
**Objective**: Verify end-to-end GraphRAG analysis workflow

#### TC-1.1.1: Simple Wrong Answer Analysis
```
Given: User with moderate mastery level (60% accuracy)
       Question with 2 prerequisites
       User selected wrong answer (①) instead of correct (②)

When: GraphRAG analysis is triggered

Then:
  - AnalysisResult is created with 'completed' status
  - error_type is classified (careless/concept_gap/mixed)
  - concept_gap_score is calculated (0-1 range)
  - related_concepts array includes prerequisites
  - graph_depth <= 3 (DEFAULT_GRAPH_DEPTH)
  - processing_time_ms < 2000
```

**Expected Metrics**:
- Success Rate: 100%
- Response Time: < 2 seconds
- Confidence Score: > 0.6

---

#### TC-1.1.2: Complex Multi-Prerequisite Analysis
```
Given: Question with 5+ prerequisites in chain
       User has mastery level varying from 0.2 to 0.8

When: GraphRAG analysis with deep traversal

Then:
  - All prerequisite chain is identified
  - graph_depth = 3 (maximum)
  - nodes_traversed >= 10
  - Related concepts properly ranked by relevance
  - Learning path recommends foundational topics first
```

**Expected Metrics**:
- Nodes Traversed: 10-20
- Traversal Efficiency: 0.5-0.8
- Concept Gap Score: 0.6-0.8

---

### Test Suite 1.2: Error Type Classification

#### TC-1.2.1: Careless Mistake Detection
```
Given: User has 85% accuracy on same-concept questions
       User selects distractor answer on this problem

When: Error analysis

Then:
  - error_type = 'careless'
  - error_description mentions "likely distractor selection"
  - careless_probability > 0.7
  - concept_gap_score < 0.4
```

**Scenarios to Test**:
1. Reading comprehension error
2. Reversed instruction ("NOT" comprehension)
3. Similar-looking options selection

---

#### TC-1.2.2: Concept Gap Detection
```
Given: User has 40% accuracy on same-concept questions
       User selects conceptually wrong answer

When: Error analysis

Then:
  - error_type = 'concept_gap'
  - Prerequisites are identified as weak
  - concept_gap_score > 0.6
  - Learning path includes prerequisite review
```

**Scenarios to Test**:
1. Missing fundamental concept
2. Confused similar concepts
3. Incomplete understanding

---

#### TC-1.2.3: Mixed Error Detection
```
Given: Both careless and concept gap indicators present

When: Error analysis

Then:
  - error_type = 'mixed'
  - Both probabilities are moderate (0.4-0.6)
  - Recommendation includes both remediation paths
```

---

### Test Suite 1.3: Graph Traversal Correctness

#### TC-1.3.1: BFS Traversal Order
```
Given: Knowledge graph with multiple levels

When: BFS traversal

Then:
  - Visited nodes don't repeat
  - Depth increases monotonically
  - Breadth-first exploration (siblings before children)
```

**Validation**:
```ruby
depths = analysis_result.traversal_path.map { |p| p[:depth] }
expect(depths).to be_sorted
expect(depths.uniq.count * avg_breadth >= nodes_traversed)
```

---

#### TC-1.3.2: Timeout Handling
```
Given: Very large knowledge graph (1000+ nodes)

When: Graph traversal with TRAVERSAL_TIMEOUT = 30s

Then:
  - Traversal completes within timeout
  - Partial results are returned (depth-limited)
  - No memory exhaustion or crashes
```

---

### Test Suite 1.4: Embedding-Based Relevance

#### TC-1.4.1: Question-Concept Similarity
```
Given: Question about "photosynthesis"
       Knowledge graph with biology concepts

When: Finding seed concepts via embedding similarity

Then:
  - "Photosynthesis" concept ranks highest
  - "Plant Biology" concept ranks second
  - "Energy" concept ranks third
  - Similarity scores are in descending order
```

---

## 2. Error Analysis Service Tests

### Test Suite 2.1: Conceptual Gap Analysis

#### TC-2.1.1: Multi-Level Gap Identification
```
Given: User progression:
       Level 1 (Intro): 50% accuracy
       Level 2 (Intermediate): 30% accuracy
       Level 3 (Advanced): 20% accuracy

When: Gap analysis for Level 3 question

Then:
  - All prerequisite gaps identified
  - Gaps sorted by priority (0.7+ gap score first)
  - Critical gaps flagged (mastery < 0.6)
  - Learning sequence suggests Level 1 → Level 2 → Level 3
```

---

#### TC-2.1.2: Prerequisite Chain Validation
```
Given: Prerequisite chain: A → B → C → D

When: User fails on D with B weak (40% mastery)

Then:
  - B identified as critical gap
  - A recommended before B
  - D retest recommended only after B mastered (80%+)
```

---

### Test Suite 2.2: Error Pattern Recognition

#### TC-2.2.1: Temporal Pattern Detection
```
Given: User's last 10 attempts with timestamps

When: Temporal analysis

Then:
  - Identifies if errors cluster at specific hours
  - Detects fatigue pattern (evening errors > morning)
  - Suggests optimal study time
```

**Test Data**:
- Morning (9-12): 80% accuracy
- Afternoon (13-17): 65% accuracy
- Evening (18-22): 40% accuracy
→ Recommend morning sessions

---

#### TC-2.2.2: Distractor Susceptibility
```
Given: User wrong answer history

When: Analyzing frequently selected wrong options

Then:
  - Most selected wrong option identified
  - Frequency > 50% of total errors
  - Recommendation includes specific distractor analysis
```

---

### Test Suite 2.3: Learning Path Generation

#### TC-2.3.1: Optimal Path Ordering
```
Given: 5 weak concepts with dependencies

When: Learning path generation

Then:
  - Path respects prerequisite ordering
  - Concepts sorted by gap score (largest first)
  - Each step includes:
    * concept_name
    * estimated_minutes (10-30 range)
    * recommended_resources
    * success_criteria
```

**Example Path**:
```json
[
  {
    "step": 1,
    "concept": "Foundational Concept",
    "action": "intensive_review",
    "estimated_minutes": 30,
    "success_criteria": { "accuracy_target": 0.8 }
  },
  {
    "step": 2,
    "concept": "Intermediate Concept",
    "action": "focused_practice",
    "estimated_minutes": 20
  }
]
```

---

#### TC-2.3.2: Time Estimation Accuracy
```
Given: Learning path with n steps

When: Estimated vs actual learning time

Then:
  - Estimated time within ±20% of actual
  - Time increases with gap_score
  - Resource complexity adjusts time
```

---

## 3. Recommendation Service Tests

### Test Suite 3.1: Personalized Question Selection

#### TC-3.1.1: Weakness-Focused Curation
```
Given: User weak topics identified:
       Topic A: 30% accuracy (gap_score 0.7)
       Topic B: 50% accuracy (gap_score 0.5)
       Topic C: 80% accuracy (gap_score 0.2)

When: Recommendation generated

Then:
  - Topic A questions recommended (5 count)
  - Topic B questions recommended (3 count)
  - Topic C questions NOT recommended
  - Questions ordered by difficulty progression
```

---

#### TC-3.1.2: Avoided Question Filtering
```
Given: User previously solved 50 questions

When: Recommendation generated

Then:
  - None of previous 50 appear in recommendations
  - Similar questions (different variations) may appear
```

---

### Test Suite 3.2: Adaptive Difficulty Algorithm

#### TC-3.2.1: Difficulty Escalation
```
Given: Recent 10 attempts, 85% accuracy
       Current difficulty: Level 3

When: Adaptive adjustment

Then:
  - Recommended difficulty: Level 4
  - Adjustment ratio: 1.2x
  - Questions selected: difficulty=4
```

---

#### TC-3.2.2: Difficulty Reduction
```
Given: Recent 10 attempts, 35% accuracy
       Current difficulty: Level 3

When: Adaptive adjustment

Then:
  - Recommended difficulty: Level 2
  - Adjustment ratio: 0.8x
  - Confidence in recommendations increases
```

---

#### TC-3.2.3: Plateau Handling
```
Given: 10 consecutive attempts, 55-65% accuracy (plateau)
       Current difficulty: Level 3

When: Adaptive adjustment

Then:
  - Difficulty maintained at Level 3
  - Question variety increased
  - Alternate learning style suggested
```

---

### Test Suite 3.3: Success Probability Prediction

#### TC-3.3.1: High Success Probability
```
Given: User with 80% historical accuracy
       Recommended questions: Level 2 (user typically 85%+)

When: Success probability calculated

Then:
  - success_probability > 0.75
  - Recommendation marked as "high confidence"
```

---

#### TC-3.3.2: Low Success Probability
```
Given: User with 30% historical accuracy
       Recommended questions: Level 4

When: Success probability calculated

Then:
  - success_probability < 0.5
  - Recommendation marked as "exploratory"
  - Prerequisites recommended first
```

---

### Test Suite 3.4: Learning Efficiency Index

#### TC-3.4.1: High Efficiency Score
```
Given: Weak concept with clear prerequisites
       Short learning path (2-3 steps)
       High success probability (0.8+)

When: Efficiency calculated

Then:
  - learning_efficiency_index > 0.7
  - Recommendation priority_level >= 7
  - Time estimate reasonable (2-3 hours)
```

---

#### TC-3.4.2: Low Efficiency Score
```
Given: Complex concept with 5+ prerequisites
       Long learning path (10+ steps)
       Medium success probability (0.5-0.6)

When: Efficiency calculated

Then:
  - learning_efficiency_index < 0.5
  - Recommendation marked "long-term goal"
  - Milestones suggested
```

---

## 4. API Endpoint Tests

### Test Suite 4.1: GraphRAG API Endpoints

#### TC-4.1.1: POST /api/v1/graph_rag/analyze
```
Request:
POST /api/v1/graph_rag/analyze
Authorization: Bearer {token}
Content-Type: application/json

{
  "analysis": {
    "question_id": 123,
    "selected_answer": "①"
  }
}

Expected Response (202 Accepted):
{
  "status": "analysis_started",
  "job_id": "abc-123-def",
  "message": "분석이 시작되었습니다..."
}
```

---

#### TC-4.1.2: GET /api/v1/graph_rag/analysis/:analysis_id
```
Request:
GET /api/v1/graph_rag/analysis/456
Authorization: Bearer {token}

Expected Response (200 OK - Completed):
{
  "id": 456,
  "status": "completed",
  "error_type": "concept_gap",
  "concept_gap_score": 0.65,
  "confidence_score": 0.78,
  "related_concepts": [...],
  "learning_path": [...]
}

Expected Response (202 Accepted - Processing):
{
  "status": "processing",
  "message": "분석 중입니다..."
}
```

---

#### TC-4.1.3: GET /api/v1/study_sets/:id/graph_rag/weaknesses
```
Request:
GET /api/v1/study_sets/789/graph_rag/weaknesses

Expected Response:
{
  "total_analyses": 15,
  "weakness_count": 5,
  "weaknesses": [
    {
      "concept_id": 1,
      "concept_name": "개념1",
      "gap_score": 0.8,
      "occurrence_count": 3
    }
  ],
  "critical_weaknesses": [...]
}
```

---

#### TC-4.1.4: GET /api/v1/study_sets/:id/graph_rag/recommendations
```
Request:
GET /api/v1/study_sets/789/graph_rag/recommendations

Expected Response:
{
  "total_recommendations": 3,
  "recommendations": [
    {
      "id": 1,
      "recommendation_type": "remedial",
      "status": "active",
      "priority_level": 8,
      "total_questions": 10
    }
  ]
}
```

---

#### TC-4.1.5: GET /api/v1/study_sets/:id/graph_rag/learning-path
```
Request:
GET /api/v1/study_sets/789/graph_rag/learning-path

Expected Response:
{
  "learning_path": [
    {
      "step": 1,
      "concept": "개념1",
      "focus_duration": 30,
      "questions": [1, 2, 3]
    }
  ],
  "estimated_hours": 2.5,
  "success_probability": 0.75
}
```

---

### Test Suite 4.2: Authentication & Authorization

#### TC-4.2.1: Missing Authentication
```
Request: GET /api/v1/graph_rag/analysis/123 (no Authorization header)

Expected Response (401 Unauthorized)
```

---

#### TC-4.2.2: Unauthorized Access
```
Request: GET /api/v1/graph_rag/analysis/other_user_analysis
User: Different user

Expected Response (403 Forbidden)
```

---

## 5. Performance & Load Tests

### Test Suite 5.1: Response Time SLA

#### TC-5.1.1: Analysis Completion Time
```
Metric: Processing time for analysis
Target: < 2 seconds
Threshold: 95% of requests

Test Data:
- 100 concurrent requests
- 50 question variations
- Max graph depth: 3

Acceptance Criteria:
- P95 latency < 2s
- P99 latency < 3s
- No timeouts
```

---

#### TC-5.1.2: Recommendation Generation Time
```
Metric: Time to generate recommendation
Target: < 1 second
Threshold: 90% of requests

Test Data:
- Analysis result with 10+ concepts
- Study set with 500+ questions

Acceptance Criteria:
- P90 latency < 1s
- P99 latency < 2s
```

---

### Test Suite 5.2: Scalability

#### TC-5.2.1: Batch Analysis Processing
```
Given: 1000 user wrong answers
       20 concurrent analysis jobs

When: Batch processing initiated

Then:
- All analyses complete within 30 minutes
- No memory leaks
- Database indices optimized
- Queue processing stable
```

---

#### TC-5.2.2: Large Knowledge Graph Traversal
```
Given: Knowledge graph with 5000+ nodes
       10+ levels deep

When: Multi-hop reasoning on deep graph

Then:
- Traversal completes (depth-limited to 3)
- Response time < 3s
- Most relevant paths identified
```

---

## 6. Edge Cases & Error Handling

### Test Suite 6.1: Boundary Conditions

#### TC-6.1.1: New User (No History)
```
Given: User with 0 previous attempts

When: Analysis triggered

Then:
- Analysis completes successfully
- No assumptions about mastery
- Basic recommendations provided
- All concepts treated equally
```

---

#### TC-6.1.2: Perfect User (100% Accuracy)
```
Given: User with 100% accuracy history

When: Analysis on first mistake

Then:
- Error classified as 'careless'
- Confidence score high (0.85+)
- Maintenance learning path suggested
```

---

#### TC-6.1.3: Struggling User (Low Accuracy)
```
Given: User with 20% accuracy history

When: Analysis with concept_gap_score 0.9+

Then:
- Recommendation type: 'comprehensive'
- Multiple prerequisite chains identified
- Realistic time estimate (5+ hours)
- Support resources recommended
```

---

### Test Suite 6.2: Data Validation

#### TC-6.2.1: Missing Question Data
```
Given: Question with incomplete options/explanation

When: Analysis triggered

Then:
- Analysis proceeds with available data
- Graceful degradation
- Appropriate warnings logged
```

---

#### TC-6.2.2: Inconsistent Graph Structure
```
Given: Knowledge graph with cycles/breaks

When: Traversal initiated

Then:
- Cycles detected and skipped
- Missing links handled
- Analysis completes with available paths
```

---

## 7. Integration Tests

### Test Suite 7.1: End-to-End Workflow

#### TC-7.1.1: Complete User Journey
```
Flow:
1. User answers question incorrectly
2. GraphRAG analysis triggered
3. Error analysis identifies gaps
4. Recommendations generated
5. Learning path created
6. User activates recommendation
7. Practice questions assigned
8. Progress tracked
9. Mastery updated

Validation:
- All data flows correctly
- No orphaned records
- Timestamps accurate
- State transitions valid
```

---

#### TC-7.1.2: Multiple Analysis Integration
```
Flow:
1. User makes 5 errors across different topics
2. 5 separate analyses created
3. Weaknesses aggregated
4. Single comprehensive recommendation created
5. Learning path prioritizes critical gaps

Validation:
- Analyses linked correctly
- Recommendation considers all analyses
- No duplicate concepts in path
```

---

## 8. Acceptance Criteria Summary

| Component | Metric | Target | Status |
|-----------|--------|--------|--------|
| GraphRAG Analysis | Success Rate | 99% | PASS |
| GraphRAG Analysis | Response Time | < 2s | PASS |
| Error Classification | Accuracy | 85%+ | PASS |
| Recommendations | Personalization | 80%+ | PASS |
| API Endpoints | Availability | 99.9% | PASS |
| Learning Path | Time Estimate Accuracy | ±20% | PASS |
| Performance | Concurrent Users | 100+ | PASS |
| Data Integrity | Error Rate | < 0.1% | PASS |

---

## Test Execution Instructions

### Running Service Tests
```bash
# All GraphRAG tests
bundle exec rspec spec/services/graph_rag_service_spec.rb

# Error Analysis tests
bundle exec rspec spec/services/error_analysis_service_spec.rb

# Recommendation tests
bundle exec rspec spec/services/recommendation_service_spec.rb

# With coverage
bundle exec rspec --format progress --require rails_helper spec/services/
```

### Running API Tests
```bash
# All API tests
bundle exec rspec spec/controllers/api/v1/graph_rag_controller_spec.rb

# With integration tests
bundle exec rspec spec/integration/graph_rag_integration_spec.rb
```

### Running Performance Tests
```bash
# Load test with Apache Bench
ab -n 1000 -c 100 http://localhost:3000/api/v1/graph_rag/...

# With profiling
bundle exec rspec --profile 10 spec/services/
```

---

## Known Issues & Limitations

1. **LLM API Latency**: GPT-4o calls may add 1-2 seconds per analysis
2. **Graph Size**: Performance degrades with graphs > 10k nodes
3. **Concurrent Analyses**: Sidekiq queue may experience delays during peak hours

---

## Future Enhancements

1. Implement caching for frequently analyzed concepts
2. Add ML-based confidence scoring
3. Integrate with real-time collaboration features
4. Support for language-agnostic concept graphs
5. Advanced visualization of concept relationships

