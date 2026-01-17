class QuestionBookmark < ApplicationRecord
  belongs_to :user
  belongs_to :test_question
  belongs_to :question
  belongs_to :test_session

  validates :user_id, presence: true
  validates :test_question_id, presence: true, uniqueness: { scope: :user_id }
  validates :question_id, presence: true

  scope :active, -> { where(is_active: true) }
  scope :recent, -> { order(bookmarked_at: :desc) }
  scope :for_session, ->(session_id) { where(test_session_id: session_id) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }

  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :increment_session_bookmark_count
  after_destroy :decrement_session_bookmark_count

  # Class methods
  def self.toggle_bookmark(user:, test_question:, reason: nil)
    bookmark = find_by(user: user, test_question: test_question)

    if bookmark
      # Remove bookmark
      bookmark.destroy
      { action: 'removed', bookmark: nil }
    else
      # Create bookmark
      bookmark = create!(
        user: user,
        test_question: test_question,
        question: test_question.question,
        test_session: test_question.test_session,
        reason: reason,
        bookmarked_at: Time.current
      )
      { action: 'created', bookmark: bookmark }
    end
  end

  # Instance methods
  def deactivate!
    update!(is_active: false)
  end

  def activate!
    update!(is_active: true)
  end

  def update_reason(new_reason)
    update!(reason: new_reason)
  end

  # Check if bookmark is for current question
  def current?
    test_question.current?
  end

  private

  def set_defaults
    self.bookmarked_at ||= Time.current
    self.is_active = true if is_active.nil?
  end

  def increment_session_bookmark_count
    test_session.increment!(:bookmark_count) if test_session
  end

  def decrement_session_bookmark_count
    test_session.decrement!(:bookmark_count) if test_session
  end
end
