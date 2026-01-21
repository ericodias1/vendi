import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sizeCheckbox", "colorCheckbox", "sizeCount", "colorCount"]

  connect() {
    this.updateSizeCount()
    this.updateColorCount()
  }

  selectAllSizes() {
    this.sizeCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
      this.updateChipStyle(checkbox)
    })
    this.updateSizeCount()
  }

  deselectAllSizes() {
    this.sizeCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
      this.updateChipStyle(checkbox)
    })
    this.updateSizeCount()
  }

  selectAllColors() {
    this.colorCheckboxTargets.forEach(checkbox => {
      checkbox.checked = true
      this.updateChipStyle(checkbox)
    })
    this.updateColorCount()
  }

  deselectAllColors() {
    this.colorCheckboxTargets.forEach(checkbox => {
      checkbox.checked = false
      this.updateChipStyle(checkbox)
    })
    this.updateColorCount()
  }

  updateSizeCount() {
    const checked = this.sizeCheckboxTargets.filter(cb => cb.checked).length
    if (this.hasSizeCountTarget) {
      this.sizeCountTarget.textContent = checked
    }
  }

  updateColorCount() {
    const checked = this.colorCheckboxTargets.filter(cb => cb.checked).length
    if (this.hasColorCountTarget) {
      this.colorCountTarget.textContent = checked
    }
  }

  toggleSize(event) {
    const chip = event.currentTarget
    const checkbox = chip.previousElementSibling
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      this.updateChipStyle(checkbox)
      this.updateSizeCount()
    }
  }

  toggleColor(event) {
    const chip = event.currentTarget
    const checkbox = chip.previousElementSibling
    if (checkbox) {
      checkbox.checked = !checkbox.checked
      this.updateChipStyle(checkbox)
      this.updateColorCount()
    }
  }

  updateChipStyle(checkbox) {
    const chip = checkbox.nextElementSibling
    if (chip) {
      if (checkbox.checked) {
        chip.classList.add("bg-primary", "text-white", "border-primary")
        chip.classList.remove("bg-zinc-100", "dark:bg-zinc-800", "text-zinc-600", "dark:text-zinc-400", "border-transparent")
      } else {
        chip.classList.remove("bg-primary", "text-white", "border-primary")
        chip.classList.add("bg-zinc-100", "dark:bg-zinc-800", "text-zinc-600", "dark:text-zinc-400", "border-transparent")
      }
    }
  }
}
