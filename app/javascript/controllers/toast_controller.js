import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { duration: Number }

  connect() {
    this.show()
    
    if (this.hasDurationValue && this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.close()
      }, this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  show() {
    // Trigger animation by adding show class after a tiny delay
    requestAnimationFrame(() => {
      this.element.classList.add('toast-show')
    })
  }

  close() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    // Remove show class to trigger exit animation
    this.element.classList.remove('toast-show')
    
    // Remove element after animation completes
    setTimeout(() => {
      this.element.remove()
    }, 300) // Match CSS transition duration
  }
}
