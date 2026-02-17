import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "showIcon", "hideIcon"]

  toggle() {
    if (this.inputTarget.type === "password") {
      this.inputTarget.type = "text"
      this.showIconTarget.classList.add("hidden")
      this.hideIconTarget.classList.remove("hidden")
    } else {
      this.inputTarget.type = "password"
      this.showIconTarget.classList.remove("hidden")
      this.hideIconTarget.classList.add("hidden")
    }
  }
}
