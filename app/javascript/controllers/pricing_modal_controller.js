import { Controller } from "@hotwired/stimulus"

// Controla o modal de configuração da precificação automática.
// O conteúdo do modal é carregado de outra rota (GET pricing_path) via Turbo Frame.
export default class extends Controller {
  static targets = ["wrapper", "frame"]

  connect() {
    this.boundCloseOnSaved = this.closeOnSaved.bind(this)
    document.addEventListener("turbo:frame-load", this.boundCloseOnSaved)
  }

  disconnect() {
    document.removeEventListener("turbo:frame-load", this.boundCloseOnSaved)
  }

  open(event) {
    if (event) event.preventDefault()
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.remove("hidden")
      this.wrapperTarget.setAttribute("aria-hidden", "false")
    }
    if (this.hasFrameTarget && this.frameTarget.dataset.src && !this.frameTarget.src) {
      this.frameTarget.src = this.frameTarget.dataset.src
    }
  }

  close(event) {
    if (event && event.target !== this.wrapperTarget) return
    if (event) event.preventDefault()
    if (this.hasWrapperTarget) {
      this.wrapperTarget.classList.add("hidden")
      this.wrapperTarget.setAttribute("aria-hidden", "true")
    }
  }

  closeOnSaved(event) {
    if (event.target.id !== "pricing_modal_content") return
    const hasSaved = event.target.querySelector?.("[data-pricing-saved=true]")
    if (hasSaved) {
      this.close()
    }
  }
}
