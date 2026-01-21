import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    // Encontrar o controller pai product-form se existir
    const parentElement = this.element.closest("[data-controller*='product-form']")
    if (parentElement) {
      this.productFormController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        "product-form"
      )
    }
    
    // Definir estado inicial baseado no botão que já tem a classe ativa
    this.buttonTargets.forEach((button, index) => {
      if (button.classList.contains("bg-primary")) {
        this.currentIndex = index
      }
    })
  }

  selectNone() {
    this.updateActiveButton(0)
    if (this.productFormController) {
      this.productFormController.selectNone()
    }
  }

  selectSize() {
    this.updateActiveButton(1)
    if (this.productFormController) {
      this.productFormController.selectSize()
    }
  }

  selectColor() {
    this.updateActiveButton(2)
    if (this.productFormController) {
      this.productFormController.selectColor()
    }
  }

  selectSizeAndColor() {
    this.updateActiveButton(3)
    if (this.productFormController) {
      this.productFormController.selectSizeAndColor()
    }
  }

  updateActiveButton(index) {
    this.buttonTargets.forEach((button, i) => {
      if (i === index) {
        button.classList.add("bg-primary", "text-white", "font-bold")
        button.classList.remove("text-black", "text-zinc-700", "dark:text-zinc-300")
      } else {
        button.classList.remove("bg-primary", "text-white", "font-bold")
        if (!button.classList.contains("text-white")) {
          button.classList.add("text-zinc-700", "dark:text-zinc-300")
        }
      }
    })
    this.currentIndex = index
  }
}
