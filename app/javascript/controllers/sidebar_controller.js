import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "collapseIcon", "expandIcon"]
  static classes = ["collapsed", "expanded"]

  connect() {
    this.collapsed = localStorage.getItem("sidebar-collapsed") === "true"
    if (this.collapsed) {
      this.collapse()
    }
  }

  toggle() {
    this.collapsed = !this.collapsed
    localStorage.setItem("sidebar-collapsed", this.collapsed)

    if (this.collapsed) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  collapse() {
    this.element.classList.remove(this.expandedClass)
    this.element.classList.add(this.collapsedClass)
    this.labelTargets.forEach(el => el.classList.add("hidden"))
    this.collapseIconTarget.classList.add("hidden")
    this.expandIconTarget.classList.remove("hidden")
  }

  expand() {
    this.element.classList.remove(this.collapsedClass)
    this.element.classList.add(this.expandedClass)
    this.labelTargets.forEach(el => el.classList.remove("hidden"))
    this.collapseIconTarget.classList.remove("hidden")
    this.expandIconTarget.classList.add("hidden")
  }
}
