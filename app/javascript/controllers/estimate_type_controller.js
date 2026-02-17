import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "stats", "value"]

  connect() {
    this.activeType = "expected"
    this.updateUI()
  }

  select(event) {
    this.activeType = event.params.type
    this.updateUI()
  }

  updateUI() {
    // Update selector buttons
    this.selectorTargets.forEach(btn => {
      const type = btn.dataset.estimateTypeTypeParam
      if (type === this.activeType) {
        btn.classList.remove("border-border", "hover:border-primary/40")
        btn.classList.add("border-primary", "glow-sm")
      } else {
        btn.classList.add("border-border", "hover:border-primary/40")
        btn.classList.remove("border-primary", "glow-sm")
      }
    })

    // Show/hide stats and value elements based on estimate type
    this.statsTargets.forEach(el => {
      el.style.display = el.dataset.estimateType === this.activeType ? "" : "none"
    })

    this.valueTargets.forEach(el => {
      el.style.display = el.dataset.estimateType === this.activeType ? "" : "none"
    })
  }
}
