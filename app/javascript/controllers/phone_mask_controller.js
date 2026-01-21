// app/javascript/controllers/phone_mask_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    // Aplica máscara no valor inicial se existir
    if (this.inputTarget.value) {
      this.format()
    }
  }

  format() {
    let value = this.inputTarget.value.replace(/\D/g, "") // Remove tudo que não é dígito

    // Limita a 11 dígitos (DDD + 9 dígitos para celular)
    if (value.length > 11) {
      value = value.substring(0, 11)
    }

    if (value.length <= 10) {
      // Telefone fixo: (11) 9999-9999
      if (value.length <= 2) {
        value = value.length > 0 ? `(${value}` : value
      } else if (value.length <= 6) {
        value = `(${value.substring(0, 2)}) ${value.substring(2)}`
      } else {
        value = `(${value.substring(0, 2)}) ${value.substring(2, 6)}-${value.substring(6)}`
      }
    } else {
      // Celular: (11) 99999-9999
      if (value.length <= 2) {
        value = value.length > 0 ? `(${value}` : value
      } else if (value.length <= 7) {
        value = `(${value.substring(0, 2)}) ${value.substring(2)}`
      } else {
        value = `(${value.substring(0, 2)}) ${value.substring(2, 7)}-${value.substring(7)}`
      }
    }

    this.inputTarget.value = value
  }

  input() {
    this.format()
  }
}
