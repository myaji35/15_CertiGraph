// Stimulus controller for exam timer with auto-submit
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["timer", "warningMessage"]
  static values = {
    startedAt: String,
    timeLimit: Number,
    examSessionId: Number,
    autoSubmitUrl: String
  }

  connect() {
    this.startTime = new Date(this.startedAtValue)
    this.timeLimitSeconds = this.timeLimitValue * 60
    this.warningShown = false

    this.intervalId = setInterval(() => this.updateTimer(), 1000)
  }

  disconnect() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
    }
  }

  updateTimer() {
    const now = new Date()
    const elapsed = Math.floor((now - this.startTime) / 1000)
    const remaining = this.timeLimitSeconds - elapsed

    // Update display
    this.updateDisplay(elapsed, remaining)

    // Check for warnings and auto-submit
    if (remaining <= 0) {
      this.autoSubmit()
    } else if (remaining <= 300 && !this.warningShown) { // 5 minutes warning
      this.showWarning()
    }
  }

  updateDisplay(elapsed, remaining) {
    if (!this.hasTimerTarget) return

    let displayTime, color

    if (remaining > 0) {
      // Show remaining time
      const minutes = Math.floor(remaining / 60)
      const seconds = remaining % 60
      displayTime = `${minutes}:${seconds.toString().padStart(2, '0')}`

      if (remaining <= 60) {
        color = 'text-red-600'
      } else if (remaining <= 300) {
        color = 'text-orange-600'
      } else {
        color = 'text-gray-900'
      }
    } else {
      // Show elapsed time (overtime)
      const hours = Math.floor(elapsed / 3600)
      const minutes = Math.floor((elapsed % 3600) / 60)
      const seconds = elapsed % 60

      if (hours > 0) {
        displayTime = `${hours}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
      } else {
        displayTime = `${minutes}:${seconds.toString().padStart(2, '0')}`
      }
      color = 'text-gray-900'
    }

    this.timerTarget.textContent = displayTime
    this.timerTarget.className = `font-mono text-xl font-bold exam-timer ${color}`
  }

  showWarning() {
    this.warningShown = true

    if (this.hasWarningMessageTarget) {
      this.warningMessageTarget.classList.remove('hidden')
    } else {
      // Create warning message if not exists
      const warning = document.createElement('div')
      warning.className = 'fixed top-20 right-4 bg-orange-500 text-white px-6 py-3 rounded-lg shadow-lg z-50'
      warning.textContent = '시험 종료 5분 전입니다!'
      document.body.appendChild(warning)

      setTimeout(() => warning.remove(), 5000)
    }
  }

  async autoSubmit() {
    // Clear interval to stop timer
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }

    // Show notification
    alert('시간이 종료되었습니다. 자동으로 제출됩니다.')

    // Submit the exam
    try {
      const url = this.autoSubmitUrlValue || `/exam_sessions/${this.examSessionIdValue}/complete`

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'text/html'
        },
        redirect: 'follow'
      })

      if (response.ok) {
        // Redirect to result page
        window.location.href = response.url
      } else {
        console.error('Failed to auto-submit')
        // Force reload to trigger server-side handling
        window.location.reload()
      }
    } catch (error) {
      console.error('Error auto-submitting:', error)
      window.location.reload()
    }
  }
}
