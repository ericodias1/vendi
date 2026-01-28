// Product Import Review Alpine.js component
// Used in app/views/backoffice/product_imports/show.html.erb

export function productImportReview() {
  return {
    init() {
      // Ler dados da variável global definida no script tag
      if (window.productImportData) {
        this.rows = window.productImportData.rows || [];
        this.errors = window.productImportData.errors || [];
      } else {
        this.rows = [];
        this.errors = [];
      }
    },

    rows: [],
    errors: [],

    hasErrors(index) {
      return this.errors.some(err => err.row === index + 1);
    },

    getErrors(index) {
      const errorObj = this.errors.find(err => err.row === index + 1);
      return errorObj ? errorObj.errors : [];
    },

    getNameConflicts() {
      // Apenas exibe erros que vêm do backend
      return this.errors.filter(err => {
        return err.errors && err.errors.some(error => 
          typeof error === 'string' && (
            error.includes('nome') || 
            error.includes('Nome') ||
            error.includes('já existe') ||
            error.includes('duplicado')
          )
        );
      });
    },

    hasNameConflicts() {
      return this.getNameConflicts().length > 0;
    },

    confirmImport() {
      // Atualizar parsed_data no form antes de processar
      const form = document.getElementById('import-form');
      const parsedDataInput = form.querySelector('#product_import_parsed_data');
      if (parsedDataInput) {
        parsedDataInput.value = JSON.stringify(this.rows);
      }

      // Submeter form de processamento
      const processForm = document.getElementById('process-form');
      const processDataInput = processForm.querySelector('#parsed_data');
      if (processDataInput) {
        processDataInput.value = JSON.stringify(this.rows);
      }
      processForm.submit();
    }
  }
}
