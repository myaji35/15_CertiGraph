import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="keyboard-shortcuts"
export default class extends Controller {
  static targets = [
    "option1", "option2", "option3", "option4", "option5",
    "submitButton", "pauseButton", "bookmarkButton", "helpModal"
  ]

  static values = {
    testSessionId: Number,
    currentQuestionId: Number,
    enabled: { type: Boolean, default: true }
  }

  connect() {
    console.log("Keyboard shortcuts controller connected")
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundHandleKeydown)
    this.showShortcutHint()
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundHandleKeydown)
  }

  handleKeydown(event) {
    // Don't handle shortcuts if typing in input/textarea
    if (this.isTyping(event)) return

    // Don't handle if disabled
    if (!this.enabledValue) return

    const key = event.key.toLowerCase()
    const ctrlKey = event.ctrlKey || event.metaKey

    // Handle Ctrl+key combinations
    if (ctrlKey) {
      switch(key) {
        case 's':
          event.preventDefault()
          this.autoSave()
          break
        case 'h':
          event.preventDefault()
          this.toggleHelp()
          break
      }
      return
    }

    // Handle single key shortcuts
    switch(key) {
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
        event.preventDefault()
        this.selectOption(parseInt(key))
        break
      case ' ':
      case 'enter':
        event.preventDefault()
        this.submitOrNext()
        break
      case 'b':
        event.preventDefault()
        this.toggleBookmark()
        break
      case 'p':
        event.preventDefault()
        this.togglePause()
        break
      case 'n':
        event.preventDefault()
        this.nextQuestion()
        break
      case 'u':
        event.preventDefault()
        this.nextUnanswered()
        break
      case 'g':
        event.preventDefault()
        this.showNavigationGrid()
        break
      case '?':
        event.preventDefault()
        this.toggleHelp()
        break
      case 'escape':
        event.preventDefault()
        this.closeModals()
        break
    }
  }

  isTyping(event) {
    const target = event.target
    const tagName = target.tagName.toLowerCase()
    return (
      tagName === 'input' ||
      tagName === 'textarea' ||
      target.isContentEditable
    )
  }

  // Option selection (1-5)
  selectOption(optionNumber) {
    const targetName = `option${optionNumber}Target`

    if (this.hasTarget(`option${optionNumber}`)) {
      const optionElement = this[targetName]
      optionElement.click()
      this.showFeedback(`Option ${optionNumber} selected`)
    }
  }

  // Submit current answer or move to next
  submitOrNext() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.click()
      this.showFeedback('Answer submitted')
    }
  }

  // Toggle bookmark (B key)
  toggleBookmark() {
    if (!this.hasCurrentQuestionIdValue) return

    fetch(`/test_sessions/${this.testSessionIdValue}/bookmarks/toggle`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({
        test_question_id: this.currentQuestionIdValue
      })
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        const action = data.action === 'created' ? 'added' : 'removed'
        this.showFeedback(`Bookmark ${action}`)
        this.updateBookmarkButton(data.action === 'created')
        this.updateBookmarkCount(data.bookmark_count)
      }
    })
    .catch(error => {
      console.error('Bookmark toggle error:', error)
      this.showFeedback('Failed to toggle bookmark', 'error')
    })
  }

  // Toggle pause (P key)
  togglePause() {
    if (!this.hasTestSessionIdValue) return

    const isPaused = document.body.dataset.testPaused === 'true'
    const action = isPaused ? 'resume' : 'pause'

    fetch(`/test_sessions/${this.testSessionIdValue}/${action}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        document.body.dataset.testPaused = !isPaused
        this.showFeedback(`Test ${action}d`)

        if (action === 'pause') {
          this.showPauseOverlay()
        } else {
          this.hidePauseOverlay()
        }
      }
    })
    .catch(error => {
      console.error('Pause toggle error:', error)
      this.showFeedback('Failed to toggle pause', 'error')
    })
  }

  // Auto-save (Ctrl+S)
  autoSave() {
    if (!this.hasTestSessionIdValue) return

    fetch(`/test_sessions/${this.testSessionIdValue}/auto_save`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.showFeedback('Progress saved', 'success')
        this.updateSaveIndicator(data.last_saved_at)
      }
    })
    .catch(error => {
      console.error('Auto-save error:', error)
      this.showFeedback('Failed to save progress', 'error')
    })
  }

  // Navigate to next question (N key)
  nextQuestion() {
    const nextButton = document.querySelector('[data-action="next-question"]')
    if (nextButton) {
      nextButton.click()
    }
  }

  // Navigate to next unanswered question (U key)
  nextUnanswered() {
    if (!this.hasTestSessionIdValue) return

    fetch(`/test_sessions/${this.testSessionIdValue}/next_unanswered`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        window.location.href = `/test_sessions/${this.testSessionIdValue}?question=${data.question.question_number}`
      } else {
        this.showFeedback('All questions answered!', 'info')
      }
    })
    .catch(error => {
      console.error('Next unanswered error:', error)
    })
  }

  // Show navigation grid (G key)
  showNavigationGrid() {
    const gridButton = document.querySelector('[data-action="show-navigation-grid"]')
    if (gridButton) {
      gridButton.click()
    } else {
      // Load grid via AJAX
      if (!this.hasTestSessionIdValue) return

      fetch(`/test_sessions/${this.testSessionIdValue}/navigation_grid`, {
        headers: {
          'Accept': 'application/json'
        }
      })
      .then(response => response.json())
      .then(data => {
        this.displayNavigationGrid(data)
      })
      .catch(error => {
        console.error('Navigation grid error:', error)
      })
    }
  }

  // Toggle help modal (? key or Ctrl+H)
  toggleHelp() {
    if (this.hasHelpModalTarget) {
      this.helpModalTarget.classList.toggle('hidden')
    } else {
      this.showHelpModal()
    }
  }

  // Close all modals (Escape key)
  closeModals() {
    const modals = document.querySelectorAll('.modal:not(.hidden)')
    modals.forEach(modal => modal.classList.add('hidden'))
  }

  // UI Helper methods
  showFeedback(message, type = 'info') {
    const feedback = document.createElement('div')
    feedback.className = `fixed top-4 right-4 px-4 py-2 rounded shadow-lg z-50 ${this.feedbackClass(type)}`
    feedback.textContent = message

    document.body.appendChild(feedback)

    setTimeout(() => {
      feedback.classList.add('opacity-0', 'transition-opacity')
      setTimeout(() => feedback.remove(), 300)
    }, 2000)
  }

  feedbackClass(type) {
    const classes = {
      info: 'bg-blue-500 text-white',
      success: 'bg-green-500 text-white',
      error: 'bg-red-500 text-white',
      warning: 'bg-yellow-500 text-white'
    }
    return classes[type] || classes.info
  }

  showShortcutHint() {
    const hint = document.querySelector('[data-keyboard-hint]')
    if (hint) {
      setTimeout(() => hint.classList.remove('hidden'), 1000)
      setTimeout(() => hint.classList.add('hidden'), 5000)
    }
  }

  showHelpModal() {
    const modal = document.createElement('div')
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50'
    modal.innerHTML = `
      <div class="bg-white rounded-lg p-6 max-w-2xl w-full mx-4">
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-2xl font-bold">Keyboard Shortcuts</h2>
          <button class="text-gray-500 hover:text-gray-700" onclick="this.closest('.fixed').remove()">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <h3 class="font-semibold mb-2">Answer Selection</h3>
            <div class="space-y-1 text-sm">
              <div><kbd>1-5</kbd> Select option</div>
              <div><kbd>Space</kbd> or <kbd>Enter</kbd> Submit answer</div>
            </div>
          </div>
          <div>
            <h3 class="font-semibold mb-2">Navigation</h3>
            <div class="space-y-1 text-sm">
              <div><kbd>N</kbd> Next question</div>
              <div><kbd>U</kbd> Next unanswered</div>
              <div><kbd>G</kbd> Show grid</div>
            </div>
          </div>
          <div>
            <h3 class="font-semibold mb-2">Session Control</h3>
            <div class="space-y-1 text-sm">
              <div><kbd>B</kbd> Toggle bookmark</div>
              <div><kbd>P</kbd> Pause/Resume</div>
              <div><kbd>Ctrl+S</kbd> Save progress</div>
            </div>
          </div>
          <div>
            <h3 class="font-semibold mb-2">Other</h3>
            <div class="space-y-1 text-sm">
              <div><kbd>?</kbd> or <kbd>Ctrl+H</kbd> Show help</div>
              <div><kbd>Esc</kbd> Close modals</div>
            </div>
          </div>
        </div>
      </div>
    `
    document.body.appendChild(modal)
  }

  showPauseOverlay() {
    const overlay = document.createElement('div')
    overlay.id = 'pause-overlay'
    overlay.className = 'fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-40'
    overlay.innerHTML = `
      <div class="text-center text-white">
        <h2 class="text-4xl font-bold mb-4">Test Paused</h2>
        <p class="text-xl mb-8">Press P to resume</p>
        <button class="px-6 py-3 bg-blue-500 hover:bg-blue-600 rounded-lg text-lg"
                onclick="document.querySelector('[data-keyboard-shortcuts-target=pauseButton]')?.click()">
          Resume Test
        </button>
      </div>
    `
    document.body.appendChild(overlay)
  }

  hidePauseOverlay() {
    const overlay = document.getElementById('pause-overlay')
    if (overlay) overlay.remove()
  }

  updateBookmarkButton(isBookmarked) {
    if (this.hasBookmarkButtonTarget) {
      this.bookmarkButtonTarget.classList.toggle('bookmarked', isBookmarked)
    }
  }

  updateBookmarkCount(count) {
    const counter = document.querySelector('[data-bookmark-count]')
    if (counter) counter.textContent = count
  }

  updateSaveIndicator(timestamp) {
    const indicator = document.querySelector('[data-save-indicator]')
    if (indicator) {
      indicator.textContent = `Saved at ${new Date(timestamp).toLocaleTimeString()}`
      indicator.classList.add('flash')
      setTimeout(() => indicator.classList.remove('flash'), 1000)
    }
  }

  displayNavigationGrid(data) {
    // This would be implemented based on your UI framework
    // For now, just log it
    console.log('Navigation grid:', data)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  // Enable/disable shortcuts
  enable() {
    this.enabledValue = true
    this.showFeedback('Keyboard shortcuts enabled')
  }

  disable() {
    this.enabledValue = false
    this.showFeedback('Keyboard shortcuts disabled')
  }

  toggle() {
    this.enabledValue = !this.enabledValue
    this.showFeedback(`Keyboard shortcuts ${this.enabledValue ? 'enabled' : 'disabled'}`)
  }
}
