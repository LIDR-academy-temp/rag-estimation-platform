import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label", "collapseIcon", "expandIcon", "overlay", "sidebar", "toggleBtn"]
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
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove(this.expandedClass)
      this.sidebarTarget.classList.add(this.collapsedClass)
    }
    this.labelTargets.forEach(el => el.classList.add("hidden"))
    if (this.hasCollapseIconTarget) this.collapseIconTarget.classList.add("hidden")
    if (this.hasExpandIconTarget) this.expandIconTarget.classList.remove("hidden")
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.setAttribute("aria-expanded", "false")
      this.toggleBtnTarget.setAttribute("aria-label", "Expandir menú lateral")
    }
  }

  expand() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove(this.collapsedClass)
      this.sidebarTarget.classList.add(this.expandedClass)
    }
    this.labelTargets.forEach(el => el.classList.remove("hidden"))
    if (this.hasCollapseIconTarget) this.collapseIconTarget.classList.remove("hidden")
    if (this.hasExpandIconTarget) this.expandIconTarget.classList.add("hidden")
    if (this.hasToggleBtnTarget) {
      this.toggleBtnTarget.setAttribute("aria-expanded", "true")
      this.toggleBtnTarget.setAttribute("aria-label", "Colapsar menú lateral")
    }
  }

  toggleMobile() {
    if (this.hasSidebarTarget) {
      const isOpen = !this.sidebarTarget.classList.contains("-translate-x-full")
      if (isOpen) {
        this.closeMobile()
      } else {
        this.openMobile()
      }
    }
  }

  openMobile() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.remove("-translate-x-full")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("hidden")
    }
  }

  closeMobile() {
    if (this.hasSidebarTarget) {
      this.sidebarTarget.classList.add("-translate-x-full")
    }
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("hidden")
    }
  }
}
