// Product Import Review Alpine.js component
// Used in app/views/backoffice/product_imports/show.html.erb

export function productImportReview() {
  return {
    init() {
      // Ler dados da variável global definida no script tag
      if (window.productImportData) {
        this.rows = window.productImportData.rows || [];
        this.errors = window.productImportData.errors || [];
        const ap = window.productImportData.automatic_pricing || {};
        this.automaticPricingEnabled = !!ap.enabled;
        this.pricingConfig = {
          markup_percent: ap.markup_percent ?? 35,
          rounding_mode: ap.rounding_mode || 'up_9_90',
          use_csv_when_cost_empty: !!ap.use_csv_when_cost_empty
        };
      } else {
        this.rows = [];
        this.errors = [];
        this.automaticPricingEnabled = false;
        this.pricingConfig = { markup_percent: 35, rounding_mode: 'up_9_90', use_csv_when_cost_empty: false };
      }
      // Garantir que cada row tenha preco_venda_auto (vindo do servidor após aplicar precificação)
      this.rows.forEach(row => {
        if (row.preco_venda_auto === undefined) row.preco_venda_auto = row.preco_base_auto ?? false;
      });
    },

    rows: [],
    errors: [],
    automaticPricingEnabled: false,
    pricingConfig: { markup_percent: 35, rounding_mode: 'up_9_90', use_csv_when_cost_empty: false },
    hasErrors(index) {
      return this.errors.some(err => err.row === index + 1);
    },

    getErrors(index) {
      const errorObj = this.errors.find(err => err.row === index + 1);
      return errorObj ? errorObj.errors : [];
    },

    // Retorna erros de duplicata (nome ou produto com mesmo tamanho/marca/cor)
    getNameConflicts() {
      return this.errors.filter(err => {
        return err.errors && err.errors.some(error =>
          typeof error === 'string' && (
            error.toLowerCase().includes('nome duplicado') ||
            error.toLowerCase().includes('produto duplicado') ||
            error.toLowerCase().includes('também na linha')
          )
        );
      });
    },

    hasNameConflicts() {
      return this.getNameConflicts().length > 0;
    },

    roundingModeLabel(mode) {
      const labels = {
        down_9_90: 'Para baixo p/ 9,90',
        up_9_90: 'Para cima p/ 9,90',
        cents_90: 'Apenas centavos ,90'
      };
      return labels[mode] || mode;
    },

    formatMoney(n) {
      if (n == null) return '--';
      return Number(n).toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
    },

    getCsrfToken() {
      const meta = document.querySelector('meta[name="csrf-token"]');
      return meta ? meta.getAttribute('content') : '';
    },

    rowsForSubmit() {
      return this.rows.map(row => {
        const { _auto_price, _cost_invalid, ...rest } = row;
        return rest;
      });
    },

    confirmImport() {
      const form = document.getElementById('import-form');
      const parsedDataInput = form?.querySelector('#product_import_parsed_data');
      if (parsedDataInput) {
        parsedDataInput.value = JSON.stringify(this.rowsForSubmit());
      }
      const processForm = document.getElementById('process-form');
      const processDataInput = processForm?.querySelector('#parsed_data');
      if (processDataInput) {
        processDataInput.value = JSON.stringify(this.rowsForSubmit());
      }
      processForm?.submit();
    }
  };
}
