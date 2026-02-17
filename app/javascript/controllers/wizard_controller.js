import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["step", "panel", "connector"]

  connect() {
    this.currentStep = 0
  }

  goTo(event) {
    const index = parseInt(event.params.index, 10)
    if (isNaN(index)) return
    this.currentStep = index
    this.updateUI()
  }

  next() {
    if (this.currentStep < this.stepTargets.length - 1) {
      this.currentStep++
      this.updateUI()
    }
  }

  prev() {
    if (this.currentStep > 0) {
      this.currentStep--
      this.updateUI()
    }
  }

  updateUI() {
    this.stepTargets.forEach((step, i) => {
      step.classList.remove("bg-primary", "text-primary-foreground", "bg-primary/20", "text-primary", "bg-surface", "text-muted-foreground")

      if (i === this.currentStep) {
        step.classList.add("bg-primary", "text-primary-foreground")
      } else if (i < this.currentStep) {
        step.classList.add("bg-primary/20", "text-primary")
      } else {
        step.classList.add("bg-surface", "text-muted-foreground")
      }
    })

    this.connectorTargets.forEach((conn, i) => {
      conn.classList.remove("bg-primary", "bg-border")
      conn.classList.add(i < this.currentStep ? "bg-primary" : "bg-border")
    })

    this.panelTargets.forEach((panel, i) => {
      panel.style.display = i === this.currentStep ? "" : "none"
    })
  }
}
