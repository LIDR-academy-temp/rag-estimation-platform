import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query"]

  toggle(event) {
    const label = event.target.closest("label")
    const isChecked = event.target.checked

    label.classList.remove(
      "border-primary/40", "bg-primary/10", "text-primary",
      "border-border", "bg-surface", "text-muted-foreground", "hover:text-card-foreground"
    )

    if (isChecked) {
      label.classList.add("border-primary/40", "bg-primary/10", "text-primary")
    } else {
      label.classList.add("border-border", "bg-surface", "text-muted-foreground", "hover:text-card-foreground")
    }

    this.element.requestSubmit()
  }
}
