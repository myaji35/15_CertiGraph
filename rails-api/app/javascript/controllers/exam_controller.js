import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="exam"
export default class extends Controller {
  static targets = ["timer", "question", "option", "submitButton"]
  static values = {
    duration: Number,
    questionId: Number,
    examId: Number
  }

  connect() {
    console.log("Exam controller connected")
    this.startTimer()
    this.loadProgress()
  }

  disconnect() {
    this.stopTimer()
  }

  startTimer() {
    if (!this.hasDurationValue) return

    this.timeRemaining = this.durationValue
    this.updateTimerDisplay()

    this.timerInterval = setInterval(() => {
      this.timeRemaining--
      this.updateTimerDisplay()

      if (this.timeRemaining <= 0) {
        this.stopTimer()
        this.autoSubmit()
      }
    }, 1000)
  }

  stopTimer() {
    if (this.timerInterval) {
      clearInterval(this.timerInterval)
    }
  }

  updateTimerDisplay() {
    if (!this.hasTimerTarget) return

    const hours = Math.floor(this.timeRemaining / 3600)
    const minutes = Math.floor((this.timeRemaining % 3600) / 60)
    const seconds = this.timeRemaining % 60

    this.timerTarget.textContent = `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`

    // Visual warning when time is running out
    if (this.timeRemaining <= 300) { // 5 minutes
      this.timerTarget.classList.add('text-red-600', 'font-bold')
    }
  }

  selectOption(event) {
    const selectedOption = event.currentTarget

    // Remove previous selection
    this.optionTargets.forEach(option => {
      option.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50')
    })

    // Mark current selection
    selectedOption.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50')

    // Enable submit button
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
    }

    // Store answer locally (for recovery)
    this.saveAnswerLocally(selectedOption.dataset.optionId)
  }

  saveAnswerLocally(optionId) {
    if (!this.hasExamIdValue || !this.hasQuestionIdValue) return

    const key = `exam_${this.examIdValue}_question_${this.questionIdValue}`
    localStorage.setItem(key, optionId)
  }

  loadProgress() {
    if (!this.hasExamIdValue || !this.hasQuestionIdValue) return

    const key = `exam_${this.examIdValue}_question_${this.questionIdValue}`
    const savedOptionId = localStorage.getItem(key)

    if (savedOptionId) {
      const savedOption = this.optionTargets.find(
        option => option.dataset.optionId === savedOptionId
      )

      if (savedOption) {
        savedOption.click()
      }
    }
  }

  submitAnswer(event) {
    const selectedOption = this.optionTargets.find(
      option => option.classList.contains('ring-blue-500')
    )

    if (!selectedOption) {
      event.preventDefault()
      alert('Please select an answer')
      return
    }
  }

  autoSubmit() {
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.click()
    }
  }

  // Handle keyboard navigation
  handleKeydown(event) {
    const currentIndex = this.optionTargets.findIndex(
      option => option.classList.contains('ring-blue-500')
    )

    let nextIndex = currentIndex

    switch(event.key) {
      case 'ArrowDown':
      case 'j':
        event.preventDefault()
        nextIndex = Math.min(currentIndex + 1, this.optionTargets.length - 1)
        break
      case 'ArrowUp':
      case 'k':
        event.preventDefault()
        nextIndex = Math.max(currentIndex - 1, 0)
        break
      case 'Enter':
        event.preventDefault()
        if (currentIndex >= 0) {
          this.submitButtonTarget?.click()
        }
        break
    }

    if (nextIndex !== currentIndex && nextIndex >= 0) {
      this.optionTargets[nextIndex].click()
    }
  }
}
