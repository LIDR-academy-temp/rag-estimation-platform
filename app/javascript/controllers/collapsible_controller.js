import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["block"]

  toggle(event) {
    const block = event.target.closest("[data-collapsible-target='block']")
    if (!block) return

    const body = block.querySelector("[data-collapsible-target='body']")
    const iconExpanded = block.querySelector("[data-collapsible-target='iconExpanded']")
    const iconCollapsed = block.querySelector("[data-collapsible-target='iconCollapsed']")

    if (body) {
      const isHidden = body.style.display === "none"
      body.style.display = isHidden ? "" : "none"

      if (iconExpanded) iconExpanded.classList.toggle("hidden", !isHidden)
      if (iconCollapsed) iconCollapsed.classList.toggle("hidden", isHidden)
    }
  }
}
