import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dashboard"
export default class extends Controller {
  static targets = ["stat", "chart", "progressBar"]
  static values = {
    userId: Number,
    refreshInterval: { type: Number, default: 30000 }
  }

  connect() {
    console.log("Dashboard controller connected")
    this.subscribeToUpdates()
    this.startAutoRefresh()
  }

  disconnect() {
    this.stopAutoRefresh()
    this.unsubscribeFromUpdates()
  }

  subscribeToUpdates() {
    if (!this.hasUserIdValue) return

    // Subscribe to Action Cable channel for real-time updates
    this.subscription = this.createSubscription()
  }

  createSubscription() {
    if (typeof App === 'undefined' || !App.cable) {
      console.warn("Action Cable not available")
      return null
    }

    return App.cable.subscriptions.create(
      {
        channel: "StudyChannel",
        user_id: this.userIdValue
      },
      {
        received: (data) => {
          this.handleUpdate(data)
        }
      }
    )
  }

  unsubscribeFromUpdates() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  handleUpdate(data) {
    console.log("Received dashboard update:", data)

    switch(data.type) {
      case 'statistics_update':
        this.updateStatistics(data.statistics)
        break
      case 'progress_update':
        this.updateProgress(data.progress)
        break
      case 'chart_update':
        this.updateChart(data.chart_data)
        break
    }
  }

  updateStatistics(statistics) {
    this.statTargets.forEach(stat => {
      const key = stat.dataset.statKey
      if (statistics[key] !== undefined) {
        const valueElement = stat.querySelector('[data-stat-value]')
        if (valueElement) {
          this.animateValue(valueElement, statistics[key])
        }
      }
    })
  }

  updateProgress(progress) {
    this.progressBarTargets.forEach(bar => {
      const key = bar.dataset.progressKey
      if (progress[key] !== undefined) {
        this.animateProgressBar(bar, progress[key])
      }
    })
  }

  updateChart(chartData) {
    // Placeholder for chart update logic
    // Will be implemented when chart library is integrated
    console.log("Chart update:", chartData)
  }

  animateValue(element, newValue) {
    const currentValue = parseInt(element.textContent) || 0
    const increment = (newValue - currentValue) / 20
    let current = currentValue

    const animation = setInterval(() => {
      current += increment
      if (
        (increment > 0 && current >= newValue) ||
        (increment < 0 && current <= newValue)
      ) {
        element.textContent = newValue
        clearInterval(animation)
      } else {
        element.textContent = Math.round(current)
      }
    }, 20)
  }

  animateProgressBar(bar, percentage) {
    const progressElement = bar.querySelector('[data-progress-fill]')
    if (progressElement) {
      progressElement.style.transition = 'width 0.5s ease-in-out'
      progressElement.style.width = `${percentage}%`
    }
  }

  startAutoRefresh() {
    this.refreshTimer = setInterval(() => {
      this.refresh()
    }, this.refreshIntervalValue)
  }

  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
    }
  }

  async refresh() {
    // Fetch latest statistics via Turbo Frame
    const frame = document.querySelector('turbo-frame#dashboard-stats')
    if (frame) {
      frame.reload()
    }
  }

  // Manual refresh trigger
  refreshNow(event) {
    event.preventDefault()
    this.refresh()
  }
}
