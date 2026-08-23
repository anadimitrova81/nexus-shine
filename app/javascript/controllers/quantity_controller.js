import { Controller } from "@hotwired/stimulus"

// Stepper for the quantity number input on the product page.
export default class extends Controller {
  static targets = ["input"]

  increment() { this.#change(1) }
  decrement() { this.#change(-1) }

  #change(delta) {
    const input = this.inputTarget
    const min = parseInt(input.min || "1", 10)
    const max = parseInt(input.max || "99", 10)
    const next = (parseInt(input.value, 10) || min) + delta
    input.value = Math.min(max, Math.max(min, next))
  }
}
