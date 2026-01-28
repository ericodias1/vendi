// Product Import Alpine.js component
// Used in app/views/backoffice/product_imports/new.html.erb

export function productImport() {
  return {
    importType: 'csv',
    selectedFile: null,
    fileName: '',
    
    handleFileSelect(event, type) {
      const file = event.target.files[0]
      if (file) {
        this.selectedFile = file
        this.fileName = file.name
        // Atualizar source_type
        this.importType = type
      } else {
        this.selectedFile = null
        this.fileName = ''
      }
    },
    
    triggerFileInput(type) {
      const inputId = `${type}_file_input`
      const input = document.getElementById(inputId)
      if (input) {
        input.click()
      }
    }
  }
}

export function productImportWithSettings() {
  return {
    ...productImport(),
    autoGenerateSku: false,
    ignoreErrors: true,
    preventDuplicateNames: true
  }
}
