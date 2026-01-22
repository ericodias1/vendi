import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["quantity"]
  static values = {
    productId: String,
    productName: String,
    productPrice: Number,
    stock: Number
  }

  connect() {
    // Verificar se produto já está selecionado
    const stored = sessionStorage.getItem('draft_sale_items')
    if (stored) {
      const items = JSON.parse(stored)
      const item = items.find(i => i.product_id === this.productIdValue)
      if (item && this.hasQuantityTarget) {
        this.quantityTarget.textContent = item.quantity || 1
      }
    }
  }

  addProduct(event) {
    const saleForm = this.findSaleFormController()
    if (saleForm) {
      // Criar evento simulado
      const fakeEvent = {
        currentTarget: {
          dataset: {
            productId: this.productIdValue,
            productName: this.productNameValue,
            productPrice: this.productPriceValue,
            size: null
          }
        }
      }
      saleForm.addProduct(fakeEvent)
      
      // Mostrar stepper
      const addButton = event.currentTarget
      addButton.style.display = 'none'
      const quantitySection = this.element.querySelector('.flex.items-center.justify-between.pt-2')
      if (quantitySection) {
        quantitySection.style.display = 'flex'
      }
    }
  }

  selectSize(event) {
    const saleForm = this.findSaleFormController()
    if (saleForm) {
      saleForm.selectSize(event)
    }
  }

  increment(event) {
    const current = parseInt(this.quantityTarget.textContent) || 1
    const max = this.stockValue || 999
    
    if (current < max) {
      const newValue = current + 1
      this.quantityTarget.textContent = newValue
      this.updateItemQuantity(newValue)
    }
  }

  decrement(event) {
    const current = parseInt(this.quantityTarget.textContent) || 1
    
    if (current > 1) {
      const newValue = current - 1
      this.quantityTarget.textContent = newValue
      this.updateItemQuantity(newValue)
    } else {
      // Remover item
      this.removeItem()
      // Esconder stepper e mostrar botão adicionar
      const quantitySection = this.element.querySelector('.flex.items-center.justify-between.pt-2')
      if (quantitySection) {
        quantitySection.style.display = 'none'
      }
      const addButton = this.element.querySelector('button[data-action*="addProduct"]')
      if (addButton) {
        addButton.style.display = 'block'
      }
    }
  }

  updateItemQuantity(quantity) {
    const saleForm = this.findSaleFormController()
    if (saleForm) {
      const items = saleForm.items || []
      const item = items.find(i => i.product_id === this.productIdValue)
      if (item) {
        item.quantity = quantity
        saleForm.saveItemsToSession()
        saleForm.updateSummary()
      }
    }
  }

  removeItem() {
    const saleForm = this.findSaleFormController()
    if (saleForm) {
      saleForm.items = saleForm.items.filter(i => i.product_id !== this.productIdValue)
      saleForm.saveItemsToSession()
      saleForm.updateSummary()
    }
  }

  findSaleFormController() {
    let element = this.element.parentElement
    while (element) {
      if (element.dataset.controller && element.dataset.controller.includes('sale-form')) {
        return this.application.getControllerForElementAndIdentifier(element, 'sale-form')
      }
      element = element.parentElement
    }
    return null
  }
}
