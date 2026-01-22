// Discount Calculator Component for Alpine.js
// Used in the sales payment step to calculate and manage discounts

export function discountCalculator(initialData) {
  const {
    subtotal,
    discountEnabled: initialDiscountEnabled,
    discountType: initialDiscountType,
    discountValue: initialDiscountValue
  } = initialData;

  return {
    subtotal: parseFloat(subtotal) || 0,
    discountEnabled: initialDiscountEnabled === 'true' || initialDiscountEnabled === true,
    discountType: initialDiscountType || 'fixed',
    discountValue: parseFloat(initialDiscountValue) || 0,
    saveTimeout: null,

    saveDiscount() {
      const form = document.getElementById('discount-form');
      if (!form) return;
      
      if (!this.discountEnabled || this.discountError) {
        form.querySelector('#sale_discount_amount').value = '';
        form.querySelector('#sale_discount_percentage').value = '';
      } else {
        if (this.discountType === 'fixed') {
          form.querySelector('#sale_discount_amount').value = this.discountValue;
          form.querySelector('#sale_discount_percentage').value = '';
        } else {
          form.querySelector('#sale_discount_percentage').value = this.discountValue;
          form.querySelector('#sale_discount_amount').value = '';
        }
      }
      
      // Debounce para não salvar a cada tecla
      clearTimeout(this.saveTimeout);
      this.saveTimeout = setTimeout(() => {
        if (!this.discountError) {
          form.requestSubmit();
        }
      }, 500);
    },

    get discountAmount() {
      if (!this.discountEnabled || !this.discountValue) return 0;
      if (this.discountType === 'fixed') {
        return Math.min(this.discountValue, this.subtotal);
      } else {
        return this.subtotal * (this.discountValue / 100);
      }
    },

    get total() {
      return Math.max(0, this.subtotal - this.discountAmount);
    },

    get discountError() {
      if (!this.discountEnabled) return null;
      if (this.discountType === 'percentage' && this.discountValue > 100) {
        return 'Desconto não pode ser maior que 100%';
      }
      if (this.discountType === 'fixed' && this.discountValue > this.subtotal) {
        return 'Desconto não pode ser maior que o subtotal';
      }
      if (this.discountValue < 0) {
        return 'Desconto não pode ser negativo';
      }
      return null;
    },

    formatCurrency(value) {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(value);
    },

    formatPercentage(value) {
      return value.toFixed(0) + '%';
    }
  };
}
