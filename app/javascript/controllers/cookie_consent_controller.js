import { Controller } from "@hotwired/stimulus"

// Shows a cookie-consent banner until the visitor accepts or rejects. The
// choice is remembered in localStorage so the banner stays hidden on return.
export default class extends Controller {
  static targets = ["banner"]
  static KEY = "nexus_shine_cookie_consent"

  connect() {
    if (!localStorage.getItem(this.constructor.KEY)) {
      this.bannerTarget.hidden = false
    }
  }

  accept() { this.#store("accepted") }
  reject() { this.#store("rejected") }

  #store(value) {
    localStorage.setItem(this.constructor.KEY, value)
    this.bannerTarget.hidden = true
  }
}
