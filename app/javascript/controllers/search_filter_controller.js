import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["query"]

  search() {
    const query = this.queryTarget.value.trim()
    if (query) {
      this.element.requestSubmit()
    }
  }
}
