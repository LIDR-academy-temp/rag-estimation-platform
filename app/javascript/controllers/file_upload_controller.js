import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dropzone", "textarea", "fileInput", "submitButton"]

  dragover(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.add("border-primary/60")
  }

  dragleave() {
    this.dropzoneTarget.classList.remove("border-primary/60")
  }

  drop(event) {
    event.preventDefault()
    this.dropzoneTarget.classList.remove("border-primary/60")

    const file = event.dataTransfer.files[0]
    if (file && file.name.endsWith(".json")) {
      this.readFile(file)
    }
  }

  selectFile() {
    this.fileInputTarget.click()
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return
    this.readFile(file)
    this.fileInputTarget.value = ""
  }

  submit() {
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.classList.add("opacity-60", "cursor-not-allowed")
    this.submitButtonTarget.innerHTML = `
      <div class="h-4 w-4 mr-2 animate-spin rounded-full border-2 border-current border-t-transparent"></div>
      Procesando...
    `
  }

  readFile(file) {
    const reader = new FileReader()
    reader.onload = (e) => {
      this.textareaTarget.value = e.target.result
    }
    reader.readAsText(file)
  }
}
