import { Controller } from "@hotwired/stimulus"

// Speedy checkout shipping: type-ahead city search, office/address delivery,
// live price. Keeps the hidden order fields (city/address/postal_code) and the
// shipping_* fields in sync, and updates the order summary.
export default class extends Controller {
  static targets = [
    "cityQuery", "suggestions", "officeField", "officeSelect", "addressFields",
    "street", "zip", "result",
    "orderCity", "orderAddress", "orderZip",
    "methodField", "siteField", "officeIdField", "shipCityField", "labelField",
  ]
  static values = { sitesUrl: String, officesUrl: String, quoteUrl: String, subtotalCents: Number }

  connect() {
    this.method = "office"
    this._debounce = null
    this.applyMethod()
  }

  // --- delivery method ---

  methodChanged(event) {
    this.method = event.target.value
    this.applyMethod()
  }

  applyMethod() {
    this.methodFieldTarget.value = this.method
    this.officeFieldTarget.hidden = this.method !== "office"
    this.addressFieldsTarget.hidden = this.method !== "address"
    this.clearQuote()

    // Re-derive things for the chosen method using the already-selected city.
    if (this.siteFieldTarget.value) {
      if (this.method === "office") {
        this.loadOffices(this.siteFieldTarget.value)
      } else {
        this.syncAddress()
        this.recalc()
      }
    }
  }

  // --- city autocomplete ---

  cityInput() {
    const q = this.cityQueryTarget.value.trim()
    // typing invalidates a previously chosen city
    this.siteFieldTarget.value = ""
    this.clearQuote()
    clearTimeout(this._debounce)
    if (q.length < 2) { this.hideSuggestions(); return }
    this._debounce = setTimeout(() => this.fetchSites(q), 250)
  }

  cityKeydown(event) {
    if (event.key === "Escape") this.hideSuggestions()
  }

  async fetchSites(q) {
    const data = await this.fetchJson(`${this.sitesUrlValue}?q=${encodeURIComponent(q)}`)
    if (!data) return
    this.renderSuggestions(data.sites || [])
  }

  renderSuggestions(sites) {
    const ul = this.suggestionsTarget
    ul.innerHTML = ""
    if (sites.length === 0) { this.hideSuggestions(); return }
    for (const s of sites) {
      const li = document.createElement("li")
      li.textContent = s.label
      li.addEventListener("mousedown", (e) => { e.preventDefault(); this.selectSite(s) })
      ul.appendChild(li)
    }
    ul.hidden = false
  }

  hideSuggestions() {
    this.suggestionsTarget.hidden = true
    this.suggestionsTarget.innerHTML = ""
  }

  selectSite(site) {
    this.cityQueryTarget.value = site.label
    this.siteFieldTarget.value = site.id
    this.shipCityFieldTarget.value = site.label
    this.orderCityTarget.value = site.label       // prefill the order's city
    this.hideSuggestions()
    this.clearQuote()

    if (this.method === "office") {
      this.loadOffices(site.id)
    } else {
      this.syncAddress()
      this.recalc()
    }
  }

  // --- offices ---

  async loadOffices(siteId) {
    this.officeSelectTarget.innerHTML = "<option value=''>Зареждане…</option>"
    const data = await this.fetchJson(`${this.officesUrlValue}?site_id=${siteId}`)
    const offices = (data && data.offices) || []
    this.officeSelectTarget.innerHTML = ""
    this.addOption(this.officeSelectTarget, "", "Изберете офис")
    for (const o of offices) this.addOption(this.officeSelectTarget, o.id, o.label)
  }

  officeChanged() {
    const opt = this.officeSelectTarget.selectedOptions[0]
    this.officeIdFieldTarget.value = this.officeSelectTarget.value
    const label = opt ? opt.textContent : ""
    this.labelFieldTarget.value = label
    this.orderAddressTarget.value = label   // the office is the delivery address
    this.clearQuote()
    if (this.officeSelectTarget.value) this.recalc()
  }

  // --- address mode ---

  syncAddress() {
    if (this.method !== "address") return
    this.orderAddressTarget.value = this.streetTarget.value
    this.orderZipTarget.value = this.zipTarget.value
  }

  // --- quote ---

  async recalc() {
    const params = new URLSearchParams({ delivery_type: this.method })
    if (this.method === "office") {
      if (!this.officeIdFieldTarget.value) return
      params.set("office_id", this.officeIdFieldTarget.value)
    } else {
      if (!this.siteFieldTarget.value) return
      params.set("site_id", this.siteFieldTarget.value)
    }
    this.showResult("Изчисляване…", false)
    const data = await this.fetchJson(`${this.quoteUrlValue}?${params}`)
    if (!data) return
    this.showResult(`Цена за доставка: ${data.formatted}`, false)
    this.updateSummary(data.price_cents)
  }

  // --- helpers ---

  async fetchJson(url) {
    try {
      const res = await fetch(url, { headers: { Accept: "application/json" } })
      const data = await res.json()
      if (!res.ok) { this.showResult(data.error || "Грешка", true); return null }
      return data
    } catch (e) {
      this.showResult("Мрежова грешка", true)
      return null
    }
  }

  addOption(select, value, label) {
    const o = document.createElement("option")
    o.value = value; o.textContent = label
    select.appendChild(o)
  }

  showResult(text, isError) {
    this.resultTarget.textContent = text
    this.resultTarget.classList.toggle("is-error", !!isError)
  }

  clearQuote() {
    this.showResult("", false)
    this.updateSummary(0)
  }

  updateSummary(shippingCents) {
    const shipEl = document.getElementById("ship-amount")
    const grandEl = document.getElementById("grand-amount")
    const fmt = (cents) => (cents / 100).toFixed(2) + " €"
    if (shipEl) shipEl.textContent = shippingCents ? fmt(shippingCents) : "—"
    if (grandEl) grandEl.textContent = fmt(this.subtotalCentsValue + (shippingCents || 0))
  }
}
