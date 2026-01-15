import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["container", "badge"]
  static values = {
    userId: Number
  }

  connect() {
    console.log("Notification controller connected")
    this.subscribeToNotifications()
  }

  disconnect() {
    this.unsubscribeFromNotifications()
  }

  subscribeToNotifications() {
    if (!this.hasUserIdValue) return

    if (typeof App === 'undefined' || !App.cable) {
      console.warn("Action Cable not available")
      return
    }

    this.subscription = App.cable.subscriptions.create(
      {
        channel: "NotificationChannel",
        user_id: this.userIdValue
      },
      {
        received: (data) => {
          this.handleNotification(data)
        }
      }
    )
  }

  unsubscribeFromNotifications() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  handleNotification(data) {
    console.log("Received notification:", data)

    switch(data.type) {
      case 'pdf_parsing_complete':
        this.showToast(
          'PDF Processing Complete',
          `Your study material "${data.material_name}" is ready!`,
          'success'
        )
        break
      case 'pdf_parsing_failed':
        this.showToast(
          'PDF Processing Failed',
          `Failed to process "${data.material_name}". Please try again.`,
          'error'
        )
        break
      case 'exam_reminder':
        this.showToast(
          'Exam Reminder',
          data.message,
          'info'
        )
        break
      case 'achievement_unlocked':
        this.showToast(
          'Achievement Unlocked!',
          data.message,
          'success'
        )
        break
      default:
        this.showToast('Notification', data.message, 'info')
    }

    this.updateBadge()
  }

  showToast(title, message, type = 'info') {
    const toast = this.createToastElement(title, message, type)

    if (this.hasContainerTarget) {
      this.containerTarget.appendChild(toast)
    } else {
      document.body.appendChild(toast)
    }

    // Trigger animation
    setTimeout(() => {
      toast.classList.add('show')
    }, 10)

    // Auto dismiss after 5 seconds
    setTimeout(() => {
      this.dismissToast(toast)
    }, 5000)
  }

  createToastElement(title, message, type) {
    const toast = document.createElement('div')
    toast.className = `notification-toast fixed bottom-4 right-4 max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto overflow-hidden transform translate-x-full transition-transform duration-300 ease-in-out`

    const colorClasses = {
      success: 'border-l-4 border-green-500',
      error: 'border-l-4 border-red-500',
      info: 'border-l-4 border-blue-500',
      warning: 'border-l-4 border-yellow-500'
    }

    toast.classList.add(colorClasses[type] || colorClasses.info)

    const iconMap = {
      success: '✓',
      error: '✕',
      info: 'ℹ',
      warning: '⚠'
    }

    toast.innerHTML = `
      <div class="p-4">
        <div class="flex items-start">
          <div class="flex-shrink-0 text-2xl mr-3">
            ${iconMap[type] || iconMap.info}
          </div>
          <div class="flex-1">
            <p class="text-sm font-medium text-gray-900">${title}</p>
            <p class="mt-1 text-sm text-gray-500">${message}</p>
          </div>
          <button
            type="button"
            class="ml-3 flex-shrink-0 inline-flex text-gray-400 hover:text-gray-500"
            data-action="click->notification#dismissToast"
          >
            <span class="sr-only">Close</span>
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </button>
        </div>
      </div>
    `

    toast.querySelector('button').addEventListener('click', () => {
      this.dismissToast(toast)
    })

    return toast
  }

  dismissToast(event) {
    const toast = event.currentTarget?.closest('.notification-toast') || event

    toast.classList.remove('show')
    toast.classList.add('translate-x-full')

    setTimeout(() => {
      toast.remove()
    }, 300)
  }

  updateBadge() {
    if (!this.hasBadgeTarget) return

    const currentCount = parseInt(this.badgeTarget.textContent) || 0
    const newCount = currentCount + 1

    this.badgeTarget.textContent = newCount
    this.badgeTarget.classList.remove('hidden')

    // Animate badge
    this.badgeTarget.classList.add('animate-bounce')
    setTimeout(() => {
      this.badgeTarget.classList.remove('animate-bounce')
    }, 1000)
  }

  clearBadge() {
    if (!this.hasBadgeTarget) return

    this.badgeTarget.textContent = '0'
    this.badgeTarget.classList.add('hidden')
  }

  markAllRead() {
    this.clearBadge()

    // Send API request to mark all as read
    fetch('/api/v1/notifications/mark_all_read', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      }
    })
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}

// Add CSS for toast animation
if (!document.getElementById('notification-toast-styles')) {
  const style = document.createElement('style')
  style.id = 'notification-toast-styles'
  style.textContent = `
    .notification-toast.show {
      transform: translateX(0) !important;
    }
  `
  document.head.appendChild(style)
}
