import { Controller } from "@hotwired/stimulus"

// Updates daily goal slider UI:
// - formatted currency label
// - progress bar width
export default class extends Controller {
  static targets = ["range", "value", "fill", "thumb"]

  connect() {
    this.update()
  }

  update() {
    const input = this.rangeTarget
    const min = parseInt(input.min || "0", 10)
    const max = parseInt(input.max || "5000", 10)
    const step = parseInt(input.step || "100", 10)

    let value = parseInt(input.value || "0", 10)
    if (Number.isNaN(value)) value = 0

    // snap to step
    if (step > 0) value = Math.round(value / step) * step
    value = Math.max(min, Math.min(max, value))
    input.value = value

    const pct = max > min ? ((value - min) / (max - min)) * 100 : 0
    this.fillTarget.style.width = `${pct}%`
    this.valueTarget.textContent = this.formatBRL(value)

    // Move thumb (centered)
    if (this.hasThumbTarget) {
      this.thumbTarget.style.left = `${pct}%`
    }
  }

  formatBRL(amount) {
    return new Intl.NumberFormat("pt-BR", {
      style: "currency",
      currency: "BRL",
      maximumFractionDigits: 0,
    }).format(amount)
  }
}

