import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "summary", "itemsCount", "total", "continueButton", "continueForm",
    "itemsInput", "paymentMethodInput", "customerIdInput", 
    "discountAmountInput", "discountPercentageInput",
    "paymentGrid", "paymentButton", "discountToggle", "customerToggle"
  ]
  static values = {
    step: Number,
    subtotal: Number
  }

  connect() {
    this.items = this.loadItemsFromSession() || []
    this.selectedPaymentMethod = null
    this.discountAmount = 0
    this.discountPercentage = null
    this.customerId = null

    this.boundOnCustomerSelected = this._onCustomerSelected.bind(this)
    this.boundOnCustomerRemoved = this._onCustomerRemoved.bind(this)
    this.boundOnNewCustomerFormSubmitEnd = this._onNewCustomerFormSubmitEnd.bind(this)
    window.addEventListener("customer:selected", this.boundOnCustomerSelected)
    window.addEventListener("customer:removed", this.boundOnCustomerRemoved)
    document.addEventListener("turbo:submit-end", this.boundOnNewCustomerFormSubmitEnd)

    if (this.hasStepValue && this.stepValue === 1) {
      this.updateSummary()
    } else if (this.hasStepValue && this.stepValue === 2) {
      this.loadStep2Data()
      this.updateTotal()
    }
  }

  disconnect() {
    window.removeEventListener("customer:selected", this.boundOnCustomerSelected)
    window.removeEventListener("customer:removed", this.boundOnCustomerRemoved)
    document.removeEventListener("turbo:submit-end", this.boundOnNewCustomerFormSubmitEnd)
  }

  _onNewCustomerFormSubmitEnd(event) {
    if (this.hasStepValue && this.stepValue !== 2) return
    if (event.target?.id !== "customer-form") return
    const fr = event.detail?.fetchResponse
    if (!fr?.succeeded || !fr.response) return
    const customerId = fr.response.headers.get("X-Customer-Id")
    const customerName = fr.response.headers.get("X-Customer-Name")
    if (!customerId) return
    const detail = JSON.stringify({
      customer_id: customerId,
      customer_name: customerName ? decodeURIComponent(customerName.replace(/\+/g, " ")) : ""
    })
    window.dispatchEvent(new CustomEvent("customer:selected", { detail }))
  }

  _onCustomerSelected(event) {
    const raw = event.detail
    const data = typeof raw === "string" ? JSON.parse(raw) : raw
    if (data?.customer_id) {
      this.customerId = String(data.customer_id)
      const field = document.querySelector("#sale_customer_id")
      const form = document.getElementById("customer-form-sale")
      if (field) field.value = this.customerId
      this.updateContinueButton()
      if (form) form.requestSubmit()
    }
  }

  _onCustomerRemoved() {
    this.customerId = null
    this.updateContinueButton()
  }

  onCustomerFormSubmitEnd() {
    this.updateContinueButton()
  }

  addProduct(event) {
    const productId = event.currentTarget.dataset.productId
    const productName = event.currentTarget.dataset.productName
    const productPrice = parseFloat(event.currentTarget.dataset.productPrice || 0)
    const size = event.currentTarget.dataset.size || null

    const existingItem = this.items.find(item => 
      item.product_id === productId && item.size === size
    )

    if (existingItem) {
      existingItem.quantity = (existingItem.quantity || 0) + 1
    } else {
      this.items.push({
        product_id: productId,
        product_name: productName,
        quantity: 1,
        unit_price: productPrice,
        size: size
      })
    }

    this.saveItemsToSession()
    this.updateSummary()
    this.updateContinueButton()
  }

  selectSize(event) {
    const size = event.currentTarget.dataset.size
    const productId = event.currentTarget.closest('[data-controller*="product-selector"]').dataset.productSelectorProductIdValue
    
    // Atualizar visualmente
    event.currentTarget.closest('.flex').querySelectorAll('button').forEach(btn => {
      btn.classList.remove('bg-primary', 'text-white', 'border-primary')
      btn.classList.add('border-gray-200', 'dark:border-gray-600', 'text-gray-600', 'dark:text-gray-300')
    })
    event.currentTarget.classList.add('bg-primary', 'text-white', 'border-primary')
    event.currentTarget.classList.remove('border-gray-200', 'dark:border-gray-600', 'text-gray-600', 'dark:text-gray-300')
    
    // Adicionar produto com tamanho selecionado
    const productCard = event.currentTarget.closest('[data-controller*="product-selector"]')
    const productName = productCard.dataset.productSelectorProductNameValue
    const productPrice = parseFloat(productCard.dataset.productSelectorProductPriceValue || 0)
    
    const existingItem = this.items.find(item => 
      item.product_id === productId && item.size === size
    )

    if (existingItem) {
      existingItem.quantity = (existingItem.quantity || 0) + 1
    } else {
      this.items.push({
        product_id: productId,
        product_name: productName,
        quantity: 1,
        unit_price: productPrice,
        size: size
      })
    }

    this.saveItemsToSession()
    this.updateSummary()
    this.updateContinueButton()
    
    // Mostrar stepper
    const productItem = event.currentTarget.closest('.bg-white, .dark\\:bg-gray-800')
    const addButton = productItem.querySelector('button[data-action*="addProduct"]')
    if (addButton) {
      addButton.style.display = 'none'
    }
    const quantitySection = productItem.querySelector('.flex.items-center.justify-between.pt-2')
    if (quantitySection) {
      quantitySection.style.display = 'flex'
    }
  }

  selectPayment(event) {
    const method = event.currentTarget.dataset.paymentMethod
    this.selectedPaymentMethod = method
    this.selectPaymentButton(event.currentTarget, method)
    
    if (this.hasPaymentMethodInputTarget) {
      this.paymentMethodInputTarget.value = method
    }
    
    // Salvar no backend
    this.savePaymentMethod(method)
    
    // Atualizar botão continuar (pode precisar verificar cliente se for fiado)
    this.updateContinueButton()
  }

  toggleDiscount(event) {
    if (event.target.checked) {
      // TODO: Mostrar campos de desconto
      console.log("Desconto ativado")
    } else {
      this.discountAmount = 0
      this.discountPercentage = null
      this.updateTotal()
    }
  }

  toggleCustomer(event) {
    if (event.target.checked) {
      // TODO: Mostrar autocomplete de clientes
      console.log("Cliente ativado")
    } else {
      this.customerId = null
    }
  }

  selectCustomer(event) {
    const customerId = event.currentTarget.dataset.customerId
    const customerName = event.currentTarget.dataset.customerName

    const field = document.querySelector("#sale_customer_id")
    if (field) field.value = customerId

    window.dispatchEvent(new CustomEvent('customer:selected', {
      detail: JSON.stringify({
        customer_id: customerId,
        customer_name: customerName
      })
    }))

    this.updateContinueButton()
  }

  updateSummary() {
    if (!this.hasItemsCountTarget || !this.hasTotalTarget) return

    const totalItems = this.items.reduce((sum, item) => sum + (item.quantity || 0), 0)
    const total = this.items.reduce((sum, item) => 
      sum + ((item.quantity || 0) * (item.unit_price || 0)), 0
    )

    this.itemsCountTarget.textContent = `${totalItems} ${totalItems === 1 ? 'item selecionado' : 'itens selecionados'}`
    this.totalTarget.textContent = `Total: R$ ${total.toFixed(2).replace('.', ',')}`
  }

  updateTotal() {
    if (!this.hasTotalTarget) return

    let subtotal = this.subtotalValue || 0
    let discount = this.discountAmount || 0
    let total = subtotal - discount

    this.totalTarget.textContent = `R$ ${total.toFixed(2).replace('.', ',')}`
  }

  updateContinueButton() {
    if (!this.hasContinueButtonTarget) return

    let canContinue = true
    
    if (this.stepValue === 1) {
      canContinue = this.items.length > 0
    } else if (this.stepValue === 2) {
      // Verificar se método de pagamento está selecionado
      canContinue = this.selectedPaymentMethod !== null
      
      // Se método é fiado, cliente é obrigatório (sempre ler do DOM para refletir estado real)
      if (canContinue && this.selectedPaymentMethod === 'fiado') {
        const customerIdField = document.querySelector('#sale_customer_id')
        const customerId = (customerIdField?.value ?? '').toString().trim()
        canContinue = customerId !== ''
      }
    }

    // O botão pode ser um link ou um botão
    const button = this.continueButtonTarget.tagName === 'A' 
      ? this.continueButtonTarget 
      : this.continueButtonTarget.closest('a') || this.continueButtonTarget
    
    if (canContinue) {
      button.classList.remove('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
      if (button.disabled !== undefined) button.disabled = false
      if (button.href) {
        button.style.pointerEvents = 'auto'
      }
    } else {
      button.classList.add('opacity-50', 'cursor-not-allowed', 'pointer-events-none')
      if (button.disabled !== undefined) button.disabled = true
      if (button.href) {
        button.style.pointerEvents = 'none'
      }
    }
  }

  loadStep2Data() {
    // Carregar dados da sessão ou do backend
    const savedPaymentMethod = this.element.dataset.savedPaymentMethod || sessionStorage.getItem('draft_payment_method')
    
    if (savedPaymentMethod) {
      this.selectedPaymentMethod = savedPaymentMethod
      // Selecionar visualmente
      const button = this.paymentButtonTargets.find(btn => 
        btn.dataset.paymentMethod === savedPaymentMethod
      )
      if (button) {
        this.selectPaymentButton(button, savedPaymentMethod)
      }
    } else {
      // Selecionar automaticamente o primeiro método disponível
      const firstButton = this.paymentButtonTargets[0]
      if (firstButton) {
        const firstMethod = firstButton.dataset.paymentMethod
        this.selectedPaymentMethod = firstMethod
        this.selectPaymentButton(firstButton, firstMethod)
        // Salvar automaticamente após um pequeno delay para garantir que o DOM está pronto
        setTimeout(() => {
          this.savePaymentMethod(firstMethod)
        }, 100)
      }
    }

    // Carregar customer_id do DOM (ex.: após Turbo ou página já com cliente)
    const customerIdField = document.querySelector("#sale_customer_id")
    if (customerIdField?.value?.trim()) {
      this.customerId = customerIdField.value.trim()
    }
    
    this.updateContinueButton()
  }

  selectPaymentButton(button, method) {
    // Atualizar visualmente
    this.paymentButtonTargets.forEach(btn => {
      btn.classList.remove('bg-primary/20', 'bg-primary/10', 'border-primary', 'border-2')
      btn.classList.add('bg-white', 'dark:bg-[#1a2e20]', 'border-transparent', 'border-2')
      // Remover checkmark (qualquer elemento absolute dentro do botão)
      const checkmark = btn.querySelector('.absolute')
      if (checkmark && checkmark.classList.contains('top-2')) {
        checkmark.remove()
      }
    })
    
    button.classList.add('bg-primary/20', 'border-primary', 'border-2')
    button.classList.remove('bg-white', 'dark:bg-[#1a2e20]', 'border-transparent')
    
    // Adicionar checkmark
    if (!button.querySelector('.absolute.top-2')) {
      const checkmark = document.createElement('div')
      checkmark.className = 'absolute top-2 right-2 text-primary'
      checkmark.innerHTML = '<span class="material-symbols-outlined fill-1">check_circle</span>'
      button.appendChild(checkmark)
    }
  }

  savePaymentMethod(method) {
    // Construir URL para update_payment
    const saleId = window.location.pathname.match(/\/sales\/(\d+)/)?.[1]
    if (!saleId) return
    
    const url = `/backoffice/sales/${saleId}/details/update_payment`
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    
    const formData = new FormData()
    formData.append('payment_method', method)
    formData.append('_method', 'PUT')
    
    if (csrfToken) {
      formData.append('authenticity_token', csrfToken)
    }
    
    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
      },
      body: formData,
      credentials: 'same-origin'
    }).catch(error => {
      console.error('Error saving payment method:', error)
    })
  }

  saveItemsToSession() {
    if (this.hasItemsInputTarget) {
      this.itemsInputTarget.value = JSON.stringify(this.items)
    }
    sessionStorage.setItem('draft_sale_items', JSON.stringify(this.items))
  }

  loadItemsFromSession() {
    const stored = sessionStorage.getItem('draft_sale_items')
    return stored ? JSON.parse(stored) : []
  }
}
