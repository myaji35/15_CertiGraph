# Epic 9: CBT Test Mode - Developer Guide

## Quick Start

### 1. Run Migrations

```bash
rails db:migrate
```

This will create:
- `question_bookmarks` table
- Enhanced `test_sessions` and `test_questions` columns

### 2. Usage Examples

#### Creating a Test Session

```ruby
user = User.first
study_set = StudySet.first

session = TestSession.create!(
  user: user,
  study_set: study_set,
  test_type: 'mock_exam',
  question_count: 50,
  time_limit: 90 # minutes
)
```

#### Using TestSessionManager

```ruby
# Initialize the manager
manager = TestSessionManager.new(session)

# Pause the test
manager.pause_session
# => true

# Resume the test
manager.resume_session
# => true

# Submit an answer
result = manager.submit_answer(test_question_id, 'A')
# => { success: true, answer: <TestAnswer>, is_correct: true/false }

# Get session statistics
stats = manager.get_session_statistics
# => { session_id: 1, status: "in_progress", progress: {...}, time: {...}, ... }

# Auto-save progress
manager.auto_save
# => true

# Complete the session
manager.complete_session
# => true
```

#### Using TestNavigationService

```ruby
# Initialize the service
nav = TestNavigationService.new(session)

# Get navigation grid (all questions overview)
grid = nav.navigation_grid
# => { total_questions: 50, current_question_number: 1, questions: [...], stats: {...} }

# Jump to specific question
result = nav.jump_to_question(25)
# => { success: true, question: {...}, navigation: {...} }

# Next unanswered question
result = nav.next_unanswered
# => { success: true, question: {...}, navigation: {...} }

# Get review list
review = nav.review_list
# => { unanswered: [...], bookmarked: [...], marked: [...], total_review_items: 10 }

# Handle keyboard shortcut
result = nav.handle_keyboard_shortcut('b') # Toggle bookmark
# => { action: 'toggle_bookmark', question_id: 123 }
```

#### Managing Bookmarks

```ruby
# Toggle bookmark
result = QuestionBookmark.toggle_bookmark(
  user: current_user,
  test_question: test_question,
  reason: "Need to review this concept"
)
# => { action: 'created', bookmark: <QuestionBookmark> }
# or { action: 'removed', bookmark: nil }

# Get all bookmarks for a session
bookmarks = session.bookmarked_questions
# => ActiveRecord::Relation of bookmarked test_questions

# Use session method
result = session.bookmark_question(question_id, reason: "Important")
# => { action: 'created', bookmark: <QuestionBookmark> }
```

#### Pause/Resume Operations

```ruby
# Pause
session.pause!
session.is_paused? # => true
session.paused_at  # => 2026-01-15 12:00:00 UTC

# Resume
session.resume!
session.is_paused?  # => false
session.resumed_at  # => 2026-01-15 12:05:00 UTC

# Check time (excluding pause duration)
session.actual_time_elapsed    # => 300 (seconds)
session.adjusted_time_remaining # => 5100 (seconds)
```

#### Time Tracking

```ruby
# Session-level timing
session.actual_time_elapsed      # Excludes pause time
session.adjusted_time_remaining  # Remaining time excluding pauses
session.total_pause_duration     # Total seconds paused
session.average_time_per_question # Average seconds per question

# Question-level timing
test_question.time_started_at  # When user first viewed question
test_question.time_spent       # Total seconds on this question
test_question.answer_change_count # Times answer was changed
```

#### Statistics

```ruby
# Calculate and update statistics
session.calculate_statistics!

# Access statistics
session.progress_percentage        # => 45 (percent)
session.estimated_completion_time  # => 2026-01-15 13:30:00 UTC
session.answer_change_count        # => 12
session.bookmark_count             # => 5
session.autosave_count            # => 3
```

## API Usage

### JavaScript (Stimulus Controller)

```javascript
// In your HTML
<div data-controller="keyboard-shortcuts"
     data-keyboard-shortcuts-test-session-id-value="<%= @test_session.id %>"
     data-keyboard-shortcuts-current-question-id-value="<%= @current_question.id %>">

  <div data-keyboard-shortcuts-target="option1">Option A</div>
  <div data-keyboard-shortcuts-target="option2">Option B</div>
  <div data-keyboard-shortcuts-target="option3">Option C</div>
  <div data-keyboard-shortcuts-target="option4">Option D</div>
  <div data-keyboard-shortcuts-target="option5">Option E</div>

  <button data-keyboard-shortcuts-target="submitButton">Submit</button>
  <button data-keyboard-shortcuts-target="pauseButton">Pause</button>
  <button data-keyboard-shortcuts-target="bookmarkButton">Bookmark</button>
</div>
```

### AJAX Requests

```javascript
// Pause test
fetch(`/test_sessions/${sessionId}/pause`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  }
})
.then(response => response.json())
.then(data => console.log(data))

// Toggle bookmark
fetch(`/test_sessions/${sessionId}/bookmarks/toggle`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': csrfToken
  },
  body: JSON.stringify({
    test_question_id: questionId,
    reason: "Need to review"
  })
})
.then(response => response.json())
.then(data => console.log(data))

// Get navigation grid
fetch(`/test_sessions/${sessionId}/navigation_grid`)
  .then(response => response.json())
  .then(grid => displayGrid(grid))

// Get statistics
fetch(`/test_sessions/${sessionId}/statistics`)
  .then(response => response.json())
  .then(stats => updateUI(stats))
```

## Controller Usage

### TestSessionsController

```ruby
class MyTestController < ApplicationController
  def show
    @test_session = TestSession.find(params[:id])
    @session_manager = TestSessionManager.new(@test_session)
    @navigation_service = TestNavigationService.new(@test_session)

    # Get current question
    @current_question = @test_session.current_question

    # Get statistics
    @stats = @session_manager.get_session_statistics

    # Get navigation grid
    @grid = @navigation_service.navigation_grid
  end
end
```

### BookmarksController

```ruby
# All bookmark operations are handled by BookmarksController
# Routes are nested under test_sessions:
# POST /test_sessions/:test_session_id/bookmarks
# POST /test_sessions/:test_session_id/bookmarks/toggle
# GET  /test_sessions/:test_session_id/bookmarks
# etc.
```

## Database Schema

### question_bookmarks

| Column | Type | Description |
|--------|------|-------------|
| id | integer | Primary key |
| user_id | integer | Foreign key to users |
| test_question_id | integer | Foreign key to test_questions |
| question_id | integer | Foreign key to questions |
| test_session_id | integer | Foreign key to test_sessions |
| reason | text | Optional note about why bookmarked |
| bookmarked_at | datetime | When bookmark was created |
| is_active | boolean | Soft delete flag |
| created_at | datetime | Record creation |
| updated_at | datetime | Record update |

**Indexes:**
- `[user_id, test_question_id]` (unique)
- `[user_id, question_id]`
- `[test_session_id, is_active]`
- `bookmarked_at`

### test_sessions (new columns)

| Column | Type | Description |
|--------|------|-------------|
| paused_at | datetime | When test was paused |
| resumed_at | datetime | When test was resumed |
| total_pause_duration | integer | Total pause time in seconds |
| pause_count | integer | Number of times paused |
| is_paused | boolean | Current pause state |
| last_autosave_at | datetime | Last auto-save timestamp |
| autosave_count | integer | Number of auto-saves |
| current_question_id | integer | Currently viewing question |
| answer_change_count | integer | Total answer changes |
| bookmark_count | integer | Number of bookmarks |
| average_time_per_question | decimal | Average seconds per question |
| estimated_completion_time | datetime | Estimated finish time |

**Indexes:**
- `is_paused`
- `current_question_id`
- `last_autosave_at`

### test_questions (new columns)

| Column | Type | Description |
|--------|------|-------------|
| time_started_at | datetime | When question first viewed |
| time_spent | integer | Total seconds on question |
| answer_change_count | integer | Times answer changed |

**Indexes:**
- `time_started_at`

## Service Objects

### TestSessionManager

**Responsibilities:**
- Session lifecycle (start, pause, resume, complete, abandon)
- Answer submission and tracking
- Auto-save functionality
- Statistics calculation
- Bookmark management
- Progress snapshots

**Key Methods:**
- `pause_session` / `resume_session` - Session control
- `submit_answer(question_id, answer)` - Answer handling
- `auto_save` - Save progress
- `get_session_statistics` - Comprehensive stats
- `get_question_grid` - Grid data for UI

### TestNavigationService

**Responsibilities:**
- Question navigation
- Grid generation
- Keyboard shortcut handling
- Question filtering
- Review list generation

**Key Methods:**
- `navigation_grid` - Full grid with stats
- `jump_to_question(number)` - Navigate to specific
- `next_unanswered` - Find next unanswered
- `review_list` - Unanswered + bookmarked
- `handle_keyboard_shortcut(key)` - Process shortcuts
- `filter_questions(filters)` - Apply filters

## Testing

### RSpec Examples

```ruby
# spec/models/question_bookmark_spec.rb
RSpec.describe QuestionBookmark, type: :model do
  describe '.toggle_bookmark' do
    it 'creates bookmark when none exists' do
      result = QuestionBookmark.toggle_bookmark(
        user: user,
        test_question: test_question
      )

      expect(result[:action]).to eq('created')
      expect(result[:bookmark]).to be_persisted
    end

    it 'removes bookmark when one exists' do
      bookmark = create(:question_bookmark, user: user, test_question: test_question)

      result = QuestionBookmark.toggle_bookmark(
        user: user,
        test_question: test_question
      )

      expect(result[:action]).to eq('removed')
      expect(QuestionBookmark.exists?(bookmark.id)).to be false
    end
  end
end

# spec/models/test_session_spec.rb
RSpec.describe TestSession, type: :model do
  describe '#pause!' do
    it 'pauses the session' do
      session = create(:test_session, status: 'in_progress')

      expect(session.pause!).to be true
      expect(session.is_paused).to be true
      expect(session.paused_at).to be_present
      expect(session.pause_count).to eq(1)
    end
  end

  describe '#resume!' do
    it 'resumes paused session' do
      session = create(:test_session, is_paused: true, paused_at: 5.minutes.ago)

      expect(session.resume!).to be true
      expect(session.is_paused).to be false
      expect(session.total_pause_duration).to be > 0
    end
  end
end

# spec/services/test_session_manager_spec.rb
RSpec.describe TestSessionManager do
  let(:session) { create(:test_session) }
  let(:manager) { described_class.new(session) }

  describe '#pause_session' do
    it 'pauses the session successfully' do
      expect(manager.pause_session).to be true
      expect(session.reload.is_paused).to be true
    end
  end

  describe '#submit_answer' do
    let(:test_question) { create(:test_question, test_session: session) }

    it 'submits answer and tracks time' do
      result = manager.submit_answer(test_question.id, 'A')

      expect(result[:success]).to be true
      expect(result[:answer]).to be_persisted
    end
  end
end
```

## Common Patterns

### Auto-Save Implementation

```ruby
# In your background job or controller
class AutoSaveJob < ApplicationJob
  def perform(test_session_id)
    session = TestSession.find(test_session_id)
    manager = TestSessionManager.new(session)

    if manager.should_auto_save?
      manager.auto_save
    end
  end
end

# Schedule auto-save every 5 minutes
TestSession.active.find_each do |session|
  AutoSaveJob.set(wait: 5.minutes).perform_later(session.id)
end
```

### Real-time Statistics Update

```ruby
# In your Stimulus controller
class StatisticsController extends Controller {
  connect() {
    this.updateInterval = setInterval(() => {
      this.updateStatistics()
    }, 10000) // Update every 10 seconds
  }

  disconnect() {
    clearInterval(this.updateInterval)
  }

  updateStatistics() {
    fetch(`/test_sessions/${this.sessionId}/statistics`)
      .then(response => response.json())
      .then(stats => this.renderStats(stats))
  }
}
```

## Troubleshooting

### Issue: Bookmarks not appearing

**Check:**
1. Is `is_active` set to true?
2. Is the association loaded? Use `.includes(:question_bookmarks)`
3. Check user_id matches current_user

```ruby
# Debug
session.question_bookmarks.count
session.question_bookmarks.active.count
session.bookmarked_questions.count
```

### Issue: Time calculations incorrect

**Check:**
1. Are pause durations being tracked?
2. Is `time_started_at` set for questions?
3. Run `calculate_statistics!` to refresh

```ruby
# Debug
session.actual_time_elapsed
session.total_pause_duration
session.adjusted_time_remaining
```

### Issue: Auto-save not triggering

**Check:**
1. Is `last_autosave_at` set?
2. Has 5 minutes elapsed?
3. Is session status 'in_progress'?

```ruby
# Debug
manager = TestSessionManager.new(session)
manager.should_auto_save?
session.last_autosave_at
session.autosave_count
```

## Performance Tips

1. **Use eager loading:**
   ```ruby
   session.test_questions.includes(:test_answer, :question_bookmarks).order(:question_number)
   ```

2. **Cache navigation grid:**
   ```ruby
   Rails.cache.fetch(['nav_grid', session.id, session.updated_at]) do
     nav_service.navigation_grid
   end
   ```

3. **Batch bookmark operations:**
   ```ruby
   # Instead of individual creates
   BookmarksController#batch_create
   ```

4. **Use counter caches:**
   ```ruby
   # Already implemented in models
   session.bookmark_count  # Cached, not counted
   ```

## Additional Resources

- **Models:** `/app/models/test_session.rb`, `/app/models/question_bookmark.rb`
- **Controllers:** `/app/controllers/test_sessions_controller.rb`, `/app/controllers/bookmarks_controller.rb`
- **Services:** `/app/services/test_session_manager.rb`, `/app/services/test_navigation_service.rb`
- **JavaScript:** `/app/javascript/controllers/keyboard_shortcuts_controller.js`
- **Routes:** `/config/routes.rb` (search for "Epic 9")
- **Migrations:** `/db/migrate/20260115200003_*.rb` and `20260115200004_*.rb`

## Support

For questions or issues, check:
1. This developer guide
2. `EPIC_9_COMPLETION_SUMMARY.md`
3. Inline code comments
4. Rails console examples above
