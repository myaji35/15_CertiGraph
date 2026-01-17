# Epic 9: CBT Test Mode - Testing Checklist

## Prerequisites

Before testing, ensure migrations have been run:
```bash
cd /Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/rails-api
rails db:migrate
```

## Unit Testing (Rails Console)

### 1. Test Session Creation
```ruby
# Start Rails console
rails c

# Create test data
user = User.first || User.create!(email: 'test@example.com', password: 'password123')
study_set = StudySet.first || StudySet.create!(user: user, name: 'Test Set')

# Create test session
session = TestSession.create!(
  user: user,
  study_set: study_set,
  test_type: 'mock_exam',
  question_count: 20,
  time_limit: 60
)

# Verify creation
session.persisted? # => true
session.test_questions.count # => 20
session.status # => "in_progress"
```

**Expected Result:** ✅ Session created with 20 questions

---

### 2. Test Pause/Resume
```ruby
# Pause the session
session.pause!
session.is_paused? # => true
session.paused_at.present? # => true
session.pause_count # => 1

# Wait a moment (simulate time)
sleep 2

# Resume the session
session.resume!
session.is_paused? # => false
session.total_pause_duration # => ~2 seconds
session.resumed_at.present? # => true

# Test time calculations
session.actual_time_elapsed # Should exclude pause time
session.adjusted_time_remaining # Should account for pause
```

**Expected Results:**
- ✅ Session pauses successfully
- ✅ Pause duration tracked
- ✅ Resume works correctly
- ✅ Time calculations exclude pause

---

### 3. Test Bookmark System
```ruby
# Get a test question
tq = session.test_questions.first

# Create bookmark
result = QuestionBookmark.toggle_bookmark(
  user: user,
  test_question: tq,
  reason: "Need to review this concept"
)

result[:action] # => "created"
result[:bookmark].persisted? # => true

# Verify bookmark exists
session.reload.bookmark_count # => 1
session.bookmarked_questions.count # => 1

# Toggle again to remove
result = QuestionBookmark.toggle_bookmark(
  user: user,
  test_question: tq
)

result[:action] # => "removed"
session.reload.bookmark_count # => 0
```

**Expected Results:**
- ✅ Bookmark created with reason
- ✅ Bookmark count updated
- ✅ Toggle removes bookmark
- ✅ Count decremented

---

### 4. Test Session Manager
```ruby
# Initialize manager
manager = TestSessionManager.new(session)

# Test pause
manager.pause_session # => true
session.reload.is_paused? # => true

# Test resume
manager.resume_session # => true
session.reload.is_paused? # => false

# Test answer submission
tq = session.test_questions.first
result = manager.submit_answer(tq.id, 'A')

result[:success] # => true
result[:answer].persisted? # => true
result[:is_correct] # => true or false

# Test statistics
stats = manager.get_session_statistics

stats[:session_id] # => session.id
stats[:progress][:total_questions] # => 20
stats[:time].keys # => [:started_at, :actual_elapsed, :paused_duration, ...]

# Test grid
grid = manager.get_question_grid

grid.length # => 20
grid.first[:question_number] # => 1
grid.first[:answered] # => true or false
```

**Expected Results:**
- ✅ Manager initializes correctly
- ✅ Pause/resume work through manager
- ✅ Answer submission tracks time
- ✅ Statistics comprehensive
- ✅ Grid has all questions

---

### 5. Test Navigation Service
```ruby
# Initialize navigation
nav = TestNavigationService.new(session)

# Get navigation grid
grid = nav.navigation_grid

grid[:total_questions] # => 20
grid[:questions].length # => 20
grid[:stats].keys # => [:answered, :unanswered, :marked, :bookmarked, ...]

# Jump to question
result = nav.jump_to_question(5)

result[:success] # => true
result[:question][:question_number] # => 5
session.reload.current_question_id.present? # => true

# Next unanswered
result = nav.next_unanswered

result[:success] # => true (if any unanswered)
result[:question][:answered] # => false

# Review list
review = nav.review_list

review.keys # => [:unanswered, :bookmarked, :marked, :total_review_items]
review[:unanswered].is_a?(Array) # => true
```

**Expected Results:**
- ✅ Grid generated correctly
- ✅ Jump to question works
- ✅ Current question tracked
- ✅ Next unanswered found
- ✅ Review list accurate

---

### 6. Test Auto-Save
```ruby
# Test auto-save
manager = TestSessionManager.new(session)

# Initial save
manager.auto_save # => true
session.reload.autosave_count # => 1
session.last_autosave_at.present? # => true

# Should not auto-save again immediately
manager.should_auto_save? # => false

# Simulate time passing (5+ minutes)
session.update(last_autosave_at: 6.minutes.ago)
manager.should_auto_save? # => true

# Auto-save again
manager.auto_save # => true
session.reload.autosave_count # => 2
```

**Expected Results:**
- ✅ Auto-save increments counter
- ✅ Timestamp updated
- ✅ 5-minute check works
- ✅ Multiple saves tracked

---

### 7. Test Time Tracking
```ruby
# Submit answer to track time
tq = session.test_questions.second
tq.update(time_started_at: 30.seconds.ago)

manager = TestSessionManager.new(session)
result = manager.submit_answer(tq.id, 'B')

tq.reload.time_spent # => ~30 seconds
tq.time_started_at # => nil (cleared after submission)

# Calculate session statistics
session.calculate_statistics!

session.average_time_per_question.present? # => true
session.estimated_completion_time.present? # => true
```

**Expected Results:**
- ✅ Question time tracked
- ✅ Time cleared after submit
- ✅ Average calculated
- ✅ Estimated completion set

---

### 8. Test Complete Session
```ruby
# Answer all questions first
session.test_questions.each do |tq|
  manager.submit_answer(tq.id, ['A', 'B', 'C', 'D'].sample)
end

# Complete session
manager.complete_session # => true

session.reload.status # => "completed"
session.completed_at.present? # => true
session.score.present? # => true
session.results.present? # => true

# Check results
session.results[:completed_at].present? # => true
session.results[:statistics].present? # => true
session.results[:questions].length # => 20
```

**Expected Results:**
- ✅ All questions answered
- ✅ Session completes successfully
- ✅ Score calculated
- ✅ Results generated
- ✅ Status updated

---

## API Testing (cURL or Postman)

### Setup
```bash
# Get CSRF token and session
curl -c cookies.txt http://localhost:3000/signin

# Login (adjust based on your auth)
curl -b cookies.txt -c cookies.txt \
  -X POST http://localhost:3000/signin \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"test@example.com","password":"password123"}}'
```

### 1. Pause Test
```bash
curl -b cookies.txt \
  -X POST http://localhost:3000/test_sessions/1/pause \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Session paused",
  "paused_at": "2026-01-15T12:00:00.000Z",
  "pause_count": 1
}
```

---

### 2. Resume Test
```bash
curl -b cookies.txt \
  -X POST http://localhost:3000/test_sessions/1/resume \
  -H "Content-Type: application/json"
```

**Expected Response:**
```json
{
  "success": true,
  "message": "Session resumed",
  "resumed_at": "2026-01-15T12:05:00.000Z",
  "time_remaining": 3300
}
```

---

### 3. Toggle Bookmark
```bash
curl -b cookies.txt \
  -X POST http://localhost:3000/test_sessions/1/bookmarks/toggle \
  -H "Content-Type: application/json" \
  -d '{"test_question_id":1,"reason":"Need review"}'
```

**Expected Response:**
```json
{
  "success": true,
  "action": "created",
  "bookmark": {
    "id": 1,
    "question_number": 1,
    "reason": "Need review"
  },
  "bookmark_count": 1
}
```

---

### 4. Get Statistics
```bash
curl -b cookies.txt \
  http://localhost:3000/test_sessions/1/statistics
```

**Expected Response:**
```json
{
  "session_id": 1,
  "status": "in_progress",
  "progress": {
    "total_questions": 20,
    "answered": 5,
    "unanswered": 15,
    "percentage": 25
  },
  "time": {
    "actual_elapsed": 300,
    "paused_duration": 0,
    "time_remaining": 3300,
    "average_per_question": 60
  },
  "bookmarks": {
    "count": 1,
    "questions": [1]
  }
}
```

---

### 5. Navigation Grid
```bash
curl -b cookies.txt \
  http://localhost:3000/test_sessions/1/navigation_grid
```

**Expected Response:**
```json
{
  "total_questions": 20,
  "current_question_number": 1,
  "questions": [
    {
      "id": 1,
      "question_number": 1,
      "status": "answered",
      "answered": true,
      "marked": false,
      "bookmarked": true,
      "is_current": true
    }
  ],
  "stats": {
    "answered": 5,
    "unanswered": 15,
    "marked": 0,
    "bookmarked": 1
  }
}
```

---

### 6. Jump to Question
```bash
curl -b cookies.txt \
  -X POST http://localhost:3000/test_sessions/1/jump_to_question \
  -H "Content-Type: application/json" \
  -d '{"question_number":10}'
```

**Expected Response:**
```json
{
  "success": true,
  "question": {
    "question_number": 10,
    "content": "Question text...",
    "options": {"A": "...", "B": "..."}
  },
  "navigation": {
    "current": {"question_number": 10, "total": 20},
    "has_previous": true,
    "has_next": true
  }
}
```

---

## Browser Testing (Manual)

### 1. Keyboard Shortcuts

Load test session page and try these shortcuts:

| Key | Expected Action | Status |
|-----|----------------|--------|
| 1 | Select option 1 | ⬜ |
| 2 | Select option 2 | ⬜ |
| 3 | Select option 3 | ⬜ |
| 4 | Select option 4 | ⬜ |
| 5 | Select option 5 | ⬜ |
| Space | Submit answer | ⬜ |
| B | Toggle bookmark | ⬜ |
| P | Pause test | ⬜ |
| N | Next question | ⬜ |
| U | Next unanswered | ⬜ |
| G | Show grid | ⬜ |
| Ctrl+S | Save progress | ⬜ |
| ? | Show help | ⬜ |
| Esc | Close modals | ⬜ |

---

### 2. Visual Feedback

Test visual elements appear:

- ⬜ Feedback toast on keyboard action
- ⬜ Bookmark button changes state
- ⬜ Pause overlay displays
- ⬜ Help modal shows shortcuts
- ⬜ Save indicator updates
- ⬜ Navigation grid displays
- ⬜ Progress bar updates

---

### 3. Full Test Flow

Complete a full test session:

1. ⬜ Start test session
2. ⬜ Answer first 5 questions
3. ⬜ Bookmark 2 questions
4. ⬜ Pause test
5. ⬜ Wait 1 minute
6. ⬜ Resume test
7. ⬜ Jump to question 10
8. ⬜ Use keyboard to select answer
9. ⬜ Press Space to submit
10. ⬜ Navigate to next unanswered (U key)
11. ⬜ Press Ctrl+S to save
12. ⬜ Open navigation grid (G key)
13. ⬜ View statistics
14. ⬜ Complete all questions
15. ⬜ Review results

---

## Integration Testing

### Test Scenarios

#### Scenario 1: Bookmark Persistence
```ruby
# Test bookmarks persist across sessions
session = TestSession.find(1)
tq = session.test_questions.first

# Create bookmark
QuestionBookmark.toggle_bookmark(user: session.user, test_question: tq)

# Reload and verify
session.reload.bookmark_count # => 1

# Complete session
session.complete!

# Verify bookmark still exists
QuestionBookmark.where(test_session: session).count # => 1
```

**Expected:** ✅ Bookmarks persist after session completion

---

#### Scenario 2: Pause Time Accuracy
```ruby
session = TestSession.find(1)

# Record start time
start_time = Time.current

# Wait 60 seconds
sleep 60

# Pause for 30 seconds
session.pause!
sleep 30
session.resume!

# Wait 60 more seconds
sleep 60

# Check times
elapsed = session.actual_time_elapsed
elapsed.between?(110, 130) # => true (120 seconds ± 10)

pause_duration = session.total_pause_duration
pause_duration.between?(25, 35) # => true (30 seconds ± 5)
```

**Expected:** ✅ Pause time excluded from total

---

#### Scenario 3: Auto-Save During Test
```ruby
session = TestSession.find(1)
manager = TestSessionManager.new(session)

# Submit 10 answers
10.times do |i|
  tq = session.test_questions[i]
  manager.submit_answer(tq.id, 'A')
end

# Check if auto-save triggered
session.reload.autosave_count # => Should be > 0 if 5 min passed
```

**Expected:** ✅ Auto-save triggers automatically

---

## Performance Testing

### Load Test: Multiple Sessions

```ruby
# Create 10 concurrent sessions
users = 10.times.map { User.create!(email: "test#{_1}@example.com", password: 'password') }
study_set = StudySet.first

sessions = users.map do |user|
  TestSession.create!(
    user: user,
    study_set: study_set,
    test_type: 'mock_exam',
    question_count: 50
  )
end

# Benchmark navigation grid
require 'benchmark'

time = Benchmark.measure do
  sessions.each do |session|
    nav = TestNavigationService.new(session)
    nav.navigation_grid
  end
end

puts "Time for 10 grids: #{time.real} seconds"
# Expected: < 2 seconds
```

**Expected:** ✅ Grid generation performant

---

### Database Query Optimization

```ruby
# Enable query logging
ActiveRecord::Base.logger = Logger.new(STDOUT)

# Test navigation grid
session = TestSession.find(1)
nav = TestNavigationService.new(session)
grid = nav.navigation_grid

# Check number of queries
# Should use includes/joins to avoid N+1
```

**Expected:** ✅ No N+1 queries

---

## Error Handling

### Test Error Scenarios

```ruby
# Test pause when already paused
session.pause!
session.pause! # => false (with error)

# Test resume when not paused
session.resume!
session.resume! # => false (with error)

# Test invalid question number
nav = TestNavigationService.new(session)
result = nav.jump_to_question(999)
result[:success] # => false
result[:error].present? # => true

# Test bookmark duplicate
tq = session.test_questions.first
QuestionBookmark.toggle_bookmark(user: session.user, test_question: tq)
# Second call should remove, not error
QuestionBookmark.toggle_bookmark(user: session.user, test_question: tq)
```

**Expected:** ✅ All errors handled gracefully

---

## Final Checklist

### Code Quality
- ⬜ All methods have clear responsibilities
- ⬜ Service objects properly encapsulate logic
- ⬜ Controllers are thin
- ⬜ Models have appropriate validations
- ⬜ No N+1 queries

### Functionality
- ⬜ All 10+ keyboard shortcuts work
- ⬜ Bookmarks create/delete correctly
- ⬜ Pause/resume functional
- ⬜ Auto-save triggers
- ⬜ Navigation works
- ⬜ Statistics accurate
- ⬜ Time tracking correct

### API
- ⬜ All 16+ endpoints respond
- ⬜ JSON format correct
- ⬜ Error responses appropriate
- ⬜ Authentication enforced

### Database
- ⬜ Migrations ran successfully
- ⬜ All indexes created
- ⬜ Foreign keys in place
- ⬜ No orphaned records

### Performance
- ⬜ Grid loads < 500ms
- ⬜ API responses < 200ms
- ⬜ No memory leaks
- ⬜ Efficient queries

## Test Results Summary

Date Tested: _____________
Tester: _____________

| Category | Tests Passed | Tests Failed | Notes |
|----------|--------------|--------------|-------|
| Unit Tests | ___/8 | ___ | |
| API Tests | ___/6 | ___ | |
| Browser Tests | ___/3 | ___ | |
| Integration | ___/3 | ___ | |
| Performance | ___/2 | ___ | |
| Error Handling | ___/4 | ___ | |

**Overall Status:** ⬜ PASS ⬜ FAIL

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________

## Next Steps After Testing

If all tests pass:
1. Commit changes
2. Push to repository
3. Deploy to staging
4. User acceptance testing

If tests fail:
1. Document failures
2. Debug issues
3. Fix bugs
4. Re-run tests
5. Repeat until pass
