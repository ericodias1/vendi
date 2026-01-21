import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "overlay"]
  static values = { open: Boolean }

  connect() {
    // Start closed on mobile
    this.openValue = false
    this.openValueChanged()
  }

  toggle() {
    this.openValue = !this.openValue
  }

  close() {
    this.openValue = false
  }

  openValueChanged() {
    if (this.hasSidebarTarget) {
      if (this.openValue) {
        this.sidebarTarget.classList.remove('-translate-x-full')
        document.body.style.overflow = 'hidden'
      } else {
        this.sidebarTarget.classList.add('-translate-x-full')
        document.body.style.overflow = ''
      }
    }
    
    if (this.hasOverlayTarget) {
      if (this.openValue) {
        this.overlayTarget.classList.remove('hidden')
      } else {
        this.overlayTarget.classList.add('hidden')
      }
    }
  }

  disconnect() {
    document.body.style.overflow = ''
  }
}
