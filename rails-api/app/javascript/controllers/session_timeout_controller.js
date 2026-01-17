// Session Timeout Controller
// Tracks user activity and auto-logout after 30 minutes of inactivity

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 30 * 60 * 1000 }, // 30 minutes in milliseconds
    checkInterval: { type: Number, default: 60 * 1000 }  // Check every minute
  }

  connect() {
    console.log("Session timeout controller connected")

    // Check for expired session FIRST before updating activity
    // This allows tests to simulate expired sessions by manipulating localStorage
    this.checkSessionExpiry()

    // Update last activity on page load (only if not already expired)
    this.updateLastActivity()

    // Track user activity
    this.trackActivity()

    // Set interval to check session expiry
    this.intervalId = setInterval(() => {
      this.checkSessionExpiry()
    }, this.checkIntervalValue)
  }

  disconnect() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
    }
  }

  trackActivity() {
    // Update last activity on user interactions
    const events = ['mousedown', 'keydown', 'scroll', 'touchstart', 'click']

    events.forEach(event => {
      document.addEventListener(event, () => {
        this.updateLastActivity()
      }, { passive: true })
    })
  }

  updateLastActivity() {
    const now = Date.now()
    localStorage.setItem('lastActivity', now.toString())
  }

  checkSessionExpiry() {
    const lastActivity = localStorage.getItem('lastActivity')

    if (!lastActivity) {
      this.updateLastActivity()
      return
    }

    const now = Date.now()
    const timeSinceLastActivity = now - parseInt(lastActivity)

    // If inactive for more than 30 minutes, logout
    if (timeSinceLastActivity > this.timeoutValue) {
      console.log("Session expired due to inactivity")
      this.logout()
    }
  }

  logout() {
    // Clear session data
    localStorage.removeItem('lastActivity')
    localStorage.removeItem('token')

    // Redirect to login with flash message
    const loginUrl = new URL('/login', window.location.origin)
    loginUrl.searchParams.set('expired', 'true')
    window.location.href = loginUrl.toString()
  }
}
