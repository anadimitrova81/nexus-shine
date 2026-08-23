import { Controller } from "@hotwired/stimulus"

// Toggles the mobile navigation menu open/closed.
export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    const open = this.menuTarget.getAttribute("data-open") === "true"
    this.menuTarget.setAttribute("data-open", (!open).toString())
    this.buttonTarget.setAttribute("aria-expanded", (!open).toString())
  }
}
