import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query", "filterBtn", "results"]

  connect() {
    this.selectedTypes = []
  }

  toggleType(event) {
    const btn = event.currentTarget
    const type = btn.dataset.type

    if (this.selectedTypes.includes(type)) {
      this.selectedTypes = this.selectedTypes.filter(t => t !== type)
      btn.classList.remove("border-primary/40", "bg-primary/10", "text-primary")
      btn.classList.add("border-border", "bg-surface", "text-muted-foreground")
    } else {
      this.selectedTypes.push(type)
      btn.classList.add("border-primary/40", "bg-primary/10", "text-primary")
      btn.classList.remove("border-border", "bg-surface", "text-muted-foreground")
    }
  }

  search() {
    const query = this.queryTarget.value.trim()
    if (query) {
      this.resultsTarget.style.display = ""
    }
  }
}
