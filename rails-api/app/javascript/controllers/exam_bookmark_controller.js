// Stimulus controller for exam bookmarks
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "modal", "list"]
  static values = {
    examSessionId: Number,
    currentQuestionId: Number,
    bookmarkedQuestions: Array
  }

  connect() {
    this.bookmarkedQuestionsValue = this.bookmarkedQuestionsValue || []
    this.updateButtonState()
  }

  toggle(event) {
    event.preventDefault()

    const questionId = this.currentQuestionIdValue

    if (this.isBookmarked(questionId)) {
      this.removeBookmark(questionId)
    } else {
      this.addBookmark(questionId)
    }

    this.updateButtonState()
  }

  isBookmarked(questionId) {
    return this.bookmarkedQuestionsValue.includes(questionId)
  }

  addBookmark(questionId) {
    if (!this.isBookmarked(questionId)) {
      this.bookmarkedQuestionsValue = [...this.bookmarkedQuestionsValue, questionId]

      // Save to server if needed
      this.saveToServer('add', questionId)
    }
  }

  removeBookmark(questionId) {
    this.bookmarkedQuestionsValue = this.bookmarkedQuestionsValue.filter(id => id !== questionId)

    // Save to server if needed
    this.saveToServer('remove', questionId)
  }

  updateButtonState() {
    const isBookmarked = this.isBookmarked(this.currentQuestionIdValue)

    if (this.hasButtonTarget) {
      if (isBookmarked) {
        this.buttonTarget.classList.add('bookmarked', 'bg-amber-100', 'border-amber-500')
        this.buttonTarget.classList.remove('border-amber-300')
      } else {
        this.buttonTarget.classList.remove('bookmarked', 'bg-amber-100', 'border-amber-500')
        this.buttonTarget.classList.add('border-amber-300')
      }
    }
  }

  showList(event) {
    event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.remove('hidden')
      this.renderBookmarkList()
    }
  }

  hideList(event) {
    event.preventDefault()

    if (this.hasModalTarget) {
      this.modalTarget.classList.add('hidden')
    }
  }

  renderBookmarkList() {
    if (!this.hasListTarget) return

    if (this.bookmarkedQuestionsValue.length === 0) {
      this.listTarget.innerHTML = '<p class="text-gray-500">북마크한 문제가 없습니다</p>'
      return
    }

    const items = this.bookmarkedQuestionsValue.map((questionId, index) => {
      return `
        <div class="question-item flex items-center justify-between p-3 bg-white border rounded-lg hover:bg-gray-50">
          <span class="font-medium">문제 ${questionId}</span>
          <a href="?question=${index}" class="text-blue-600 hover:underline">보기</a>
        </div>
      `
    }).join('')

    this.listTarget.innerHTML = items
  }

  async saveToServer(action, questionId) {
    try {
      const response = await fetch(`/exam_sessions/${this.examSessionIdValue}/bookmark`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          action: action,
          question_id: questionId
        })
      })

      if (!response.ok) {
        console.warn('Failed to save bookmark')
      }
    } catch (error) {
      console.error('Error saving bookmark:', error)
    }
  }
}
