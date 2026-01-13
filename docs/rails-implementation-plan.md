# CertiGraph Rails Implementation Plan
Date: 2026-01-12
Status: Active Implementation

## Current Architecture: Rails Monolith
- Rails 7.2.3 with Hotwire (Turbo + Stimulus)
- SQLite3 Database
- Active Storage for PDF uploads
- PDF Processing with pdf-reader gem
- Background Jobs with SolidQueue
- Authentication with Devise + Google OAuth2

## Epic Implementation Status & Plan

### ✅ Epic 1: Foundation & Authentication (100% Complete)
- [x] Project initialization with Rails
- [x] Database setup (SQLite3)
- [x] User authentication (Devise + Google OAuth2)
- [x] User model with roles (free, paid, admin)
- [x] Dashboard layout
- [x] JWT middleware for API

### 🟡 Epic 2: Study Set & Material Management (60% Complete)
#### Completed:
- [x] Study Set CRUD (create, read, update, delete)
- [x] StudyMaterial model with Active Storage
- [x] PDF upload functionality with modal UI
- [x] PDF parsing service (Ruby implementation of Python chunking algorithm)
- [x] Background job for PDF processing (ProcessPdfJob)

#### Remaining Implementation:
- [ ] **Story 2.5: Upstage OCR Integration** (P0 CRITICAL)
- [ ] **Story 2.6: Advanced Question Extraction**
- [ ] **Story 2.7: Embeddings Generation** (Phase 2)
- [ ] **Story 2.8: Knowledge Graph Integration** (Phase 2)

### ❌ Epic 3: CBT Test Engine (0% Complete - NEXT PRIORITY)
- [ ] **Story 3.1: Test Configuration Modal**
- [ ] **Story 3.2: Test Session API & Model**
- [ ] **Story 3.3: CBT Interface**
- [ ] **Story 3.4: Answer Submission & Scoring**
- [ ] **Story 3.5: Results Review Page**

### 🟠 Epic 4: Analysis & Dashboard (30% Complete)
#### Completed:
- [x] Basic dashboard UI structure
- [x] Study sets display

#### Remaining Implementation:
- [ ] **Story 4.1: Statistics API**
- [ ] **Story 4.2: Dashboard Charts**
- [ ] **Story 4.3: Weak Concept Analysis** (Phase 2)
- [ ] **Story 4.4: Progress Tracking**

### 🟡 Epic 5: VIP System & Payment (75% Complete)
#### Completed:
- [x] VIP user management
- [x] VIP permission system
- [x] VIP UI indicators

#### Remaining:
- [ ] **Story 5.1: Toss Payments Integration**

## Implementation Timeline (Week 1 - Current)

### Immediate Actions (Today - Jan 12):

#### 1. Complete Upstage OCR Integration (Story 2.5)
```ruby
# app/services/upstage_ocr_service.rb
class UpstageOcrService
  UPSTAGE_API_URL = "https://api.upstage.ai/v1/document-ai/ocr"

  def initialize(api_key = ENV['UPSTAGE_API_KEY'])
    @api_key = api_key
  end

  def process_pdf(pdf_file_path)
    # Implementation here
  end
end
```

#### 2. Implement Test Engine Models (Story 3.2)
```ruby
# Models needed:
# - app/models/test_session.rb
# - app/models/test_question.rb
# - app/models/test_answer.rb
# - app/models/test_result.rb
```

#### 3. Create CBT Interface Controllers
```ruby
# Controllers needed:
# - app/controllers/test_sessions_controller.rb
# - app/controllers/test_answers_controller.rb
# - app/controllers/test_results_controller.rb
```

## Database Schema Updates Required

```ruby
# New migrations needed:
# 1. Create test_sessions table
# 2. Create test_questions table (references questions from study_materials)
# 3. Create test_answers table
# 4. Create test_results table
# 5. Add statistics columns to users table
```

## API Endpoints to Implement

### Test Engine APIs
- POST /api/v1/test_sessions - Create new test session
- GET /api/v1/test_sessions/:id - Get test session with questions
- POST /api/v1/test_sessions/:id/answers - Submit answer
- POST /api/v1/test_sessions/:id/complete - Complete test and calculate score
- GET /api/v1/test_sessions/:id/results - Get test results

### Statistics APIs
- GET /api/v1/users/:id/statistics - User statistics
- GET /api/v1/study_sets/:id/statistics - Study set statistics
- GET /api/v1/test_sessions/:id/analysis - Test performance analysis

## UI Components to Build

### Test Engine Components
1. Test Configuration Modal
2. CBT Interface (Question Display)
3. Answer Selection Component
4. Timer Component
5. Navigation Component (Previous/Next/Review)
6. Results Display Page
7. Review Answers Page

### Dashboard Components
1. Statistics Cards
2. Progress Charts (Chart.js or similar)
3. Weak Concepts Display
4. Recent Activity Feed
5. Achievement Badges

## Background Jobs to Create

```ruby
# app/jobs/calculate_statistics_job.rb
# app/jobs/generate_weak_concepts_job.rb
# app/jobs/process_test_results_job.rb
```

## Services to Implement

```ruby
# app/services/test_generator_service.rb - Generate randomized tests
# app/services/scoring_service.rb - Calculate test scores
# app/services/statistics_service.rb - Calculate user/set statistics
# app/services/weak_concept_analyzer_service.rb - Analyze weak areas
```

## Next Steps Priority Order:

1. **Week 1 (Jan 12-14)**:
   - Upstage OCR integration
   - Test engine models and migrations
   - Basic test session creation

2. **Week 1-2 (Jan 15-21)**:
   - CBT interface implementation
   - Answer submission and scoring
   - Basic results page

3. **Week 2 (Jan 22-28)**:
   - Dashboard statistics
   - Progress tracking
   - Test review functionality

4. **Week 3 (Jan 29-Feb 4)**:
   - Payment integration
   - Performance optimization
   - Bug fixes and polish

## Technical Debt & Improvements:
1. Add caching for frequently accessed data
2. Implement pagination for large datasets
3. Add comprehensive error handling
4. Implement rate limiting for API endpoints
5. Add background job monitoring
6. Implement comprehensive logging
7. Add performance monitoring (APM)