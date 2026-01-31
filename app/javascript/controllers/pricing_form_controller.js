import { Controller } from "@hotwired/stimulus"

// Atualiza o preview dinâmico da precificação (custo + markup → resultado).
export default class extends Controller {
  static targets = ["markup", "roundingMode", "costExample", "previewText"]
  static values = { calculateUrl: String }

  connect() {
    this.fetchPreview()
  }

  async fetchPreview() {
    if (!this.hasMarkupTarget || !this.hasRoundingModeTarget || !this.hasCostExampleTarget || !this.hasPreviewTextTarget) return
    const cost = parseFloat(this.costExampleTarget.value) || 0
    const markup = parseFloat(this.markupTarget.value) || 35
    const mode = this.roundingModeTarget.value || "up_9_90"
    if (cost <= 0) {
      this.previewTextTarget.textContent = `Custo R$ ${this.formatMoney(cost)} + ${markup}% = -- → Resultado: --`
      return
    }
    const url = this.calculateUrlValue || "/backoffice/product_imports/calculate_prices"
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          "Accept": "application/json"
        },
        body: JSON.stringify({ costs: [cost], markup_percent: markup, rounding_mode: mode })
      })
      const data = await res.json()
      const raw = cost * (1 + markup / 100)
      const rawStr = this.formatMoney(Math.round(raw * 100) / 100)
      const final = data.prices?.[0] != null ? this.formatMoney(data.prices[0]) : "--"
      this.previewTextTarget.textContent = `Custo R$ ${this.formatMoney(cost)} + ${markup}% = ${rawStr} → Resultado: R$ ${final}`
    } catch (e) {
      this.previewTextTarget.textContent = `Custo R$ ${this.formatMoney(cost)} + ${markup}% = -- → Resultado: --`
    }
  }

  formatMoney(n) {
    if (n == null || isNaN(n)) return "--"
    return Number(n).toLocaleString("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  }
}
