import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "fileName", "removeButton"]
  static values = { existingImage: String }

  connect() {
    // Se houver imagem existente, mostrar preview
    if (this.existingImageValue && this.existingImageValue.trim() !== "") {
      this.showPreview(this.existingImageValue)
      if (this.hasRemoveButtonTarget) {
        this.removeButtonTarget.classList.remove("hidden")
      }
    }
  }

  selectFile(event) {
    const files = Array.from(event.target.files)
    if (files.length === 0) return

    // Mostrar preview da primeira imagem
    const firstFile = files[0]
    this.showFilePreview(firstFile)
    
    // Mostrar nome do arquivo ou quantidade de arquivos
    if (files.length === 1) {
      this.showFileName(firstFile.name)
    } else {
      this.showFileName(`${files.length} arquivos selecionados`)
    }
  }

  showFilePreview(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      this.showPreview(e.target.result)
    }
    reader.readAsDataURL(file)
  }

  showPreview(imageUrl) {
    if (this.hasPreviewTarget) {
      this.previewTarget.style.backgroundImage = `url('${imageUrl}')`
      this.previewTarget.classList.remove("hidden")
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.add("hidden")
    }
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.remove("hidden")
    }
  }

  showFileName(name) {
    if (this.hasFileNameTarget) {
      const nameSpan = this.fileNameTarget.querySelector("span:last-child")
      if (nameSpan) {
        nameSpan.textContent = name
      } else {
        this.fileNameTarget.textContent = name
      }
      this.fileNameTarget.classList.remove("hidden")
    }
  }

  removeImage() {
    if (this.hasInputTarget) {
      // Criar um novo input file para limpar o valor
      const newInput = this.inputTarget.cloneNode(true)
      this.inputTarget.parentNode.replaceChild(newInput, this.inputTarget)
      this.inputTarget = newInput
      this.inputTarget.addEventListener("change", (e) => this.selectFile(e))
    }
    if (this.hasPreviewTarget) {
      this.previewTarget.classList.add("hidden")
      this.previewTarget.style.backgroundImage = ""
    }
    if (this.hasPlaceholderTarget) {
      this.placeholderTarget.classList.remove("hidden")
    }
    if (this.hasFileNameTarget) {
      this.fileNameTarget.classList.add("hidden")
      const nameSpan = this.fileNameTarget.querySelector("span:last-child")
      if (nameSpan) {
        nameSpan.textContent = ""
      } else {
        this.fileNameTarget.textContent = ""
      }
    }
    if (this.hasRemoveButtonTarget) {
      this.removeButtonTarget.classList.add("hidden")
    }
  }
}
