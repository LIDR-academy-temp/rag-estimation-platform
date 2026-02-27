import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "submitBtn", "counter", "listSection", "fileInput", "template", "addBtn"]

  add() {
    const text = this.inputTarget.value.trim()
    if (!text) return

    const name = `Reunion ${this.listTarget.children.length + 1}`
    const preview = text.substring(0, 120) + (text.length > 120 ? "..." : "")
    this.appendItem(name, preview, text)
    this.inputTarget.value = ""
    this.updateState()
  }

  remove(event) {
    event.currentTarget.closest("[data-transcription-item]").remove()
    this.updateState()
  }

  uploadFile() {
    this.fileInputTarget.click()
  }

  fileSelected() {
    const file = this.fileInputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      const text = e.target.result
      const name = file.name.replace(/\.txt$/, "")
      const preview = text.substring(0, 120) + (text.length > 120 ? "..." : "")
      this.appendItem(name, preview, text)
      this.fileInputTarget.value = ""
      this.updateState()
    }
    reader.readAsText(file)
  }

  inputChanged() {
    const hasText = this.inputTarget.value.trim().length > 0
    this.addBtnTarget.disabled = !hasText
    this.addBtnTarget.classList.toggle("opacity-50", !hasText)
    this.addBtnTarget.classList.toggle("cursor-not-allowed", !hasText)
  }

  appendItem(name, preview, fullText) {
    const template = this.templateTarget.content.cloneNode(true)
    template.querySelector("[data-name]").textContent = name
    template.querySelector("[data-preview]").textContent = preview
    template.querySelector("input[type=hidden]").value = fullText
    this.listTarget.appendChild(template)
  }

  updateState() {
    const count = this.listTarget.children.length
    const hasItems = count > 0

    this.listSectionTarget.classList.toggle("hidden", !hasItems)
    this.counterTarget.textContent = `${count} transcripcion${count === 1 ? "" : "es"}`

    this.submitBtnTarget.disabled = !hasItems
    this.submitBtnTarget.classList.toggle("opacity-50", !hasItems)
    this.submitBtnTarget.classList.toggle("cursor-not-allowed", !hasItems)

    this.inputChanged()
  }
}
