import { Controller } from "@hotwired/stimulus"

// Envia POST para adicionar/remover produto da seleção de etiquetas e atualiza o banner de contagem sem recarregar a página.
export default class extends Controller {
  static values = {
    addUrl: String,
    removeUrl: String,
    productId: String
  }

  toggle(event) {
    event.preventDefault()
    const checkbox = event.target
    const isChecked = checkbox.checked
    const url = isChecked ? this.addUrlValue : this.removeUrlValue

    const body = new URLSearchParams({
      authenticity_token: this.csrfToken,
      "product_ids[]": this.productIdValue
    })

    fetch(url, {
      method: "POST",
      headers: {
        "Accept": "application/json",
        "X-Requested-With": "XMLHttpRequest",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: body.toString()
    })
      .then((res) => {
        if (!res.ok) throw new Error(res.statusText)
        return res.json()
      })
      .then((data) => {
        this.updateBanner(data.selected_count)
      })
      .catch(() => {
        checkbox.checked = !isChecked
      })
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute("content") || ""
  }

  updateBanner(count) {
    const countEl = document.getElementById("labels_selection_count")
    const inner = document.querySelector("#labels_selection_banner .labels_selection_banner_inner")
    if (countEl) countEl.textContent = count
    if (inner) inner.style.display = count > 0 ? "" : "none"
  }
}
