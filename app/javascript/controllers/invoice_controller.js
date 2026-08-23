import { Controller } from "@hotwired/stimulus"

// "Искам фактура" — toggles the invoice fields and autofills company details
// from a Bulgarian ЕИК via /eik_lookups/:eik.
export default class extends Controller {
  static targets = ["toggle", "fields", "eik", "company", "vat", "mol", "address", "status", "lookupBtn"]
  static values = { lookupUrl: String }

  connect() {
    this.toggle()
  }

  toggle() {
    const on = this.toggleTarget.checked
    this.fieldsTarget.hidden = !on
    // ДДС № stays optional; the rest are required whenever a фактура is requested.
    for (const el of [this.eikTarget, this.companyTarget, this.molTarget, this.addressTarget]) {
      el.required = on
    }
  }

  async lookup() {
    const eik = this.eikTarget.value.trim()
    if (!/^\d{9}(\d{4})?$/.test(eik)) {
      this.setStatus("Въведете валиден ЕИК (9 или 13 цифри).", true)
      return
    }
    this.lookupBtnTarget.disabled = true
    this.setStatus("Търсене в регистъра…", false)
    try {
      const res = await fetch(`${this.lookupUrlValue}/${eik}`, { headers: { Accept: "application/json" } })
      const data = await res.json()
      if (res.ok && data.found) {
        if (data.company) this.companyTarget.value = data.company
        if (data.address) this.addressTarget.value = data.address
        if (data.vat) this.vatTarget.value = data.vat
        if (data.mol) this.molTarget.value = data.mol
        this.setStatus("Данните са попълнени от регистъра. Проверете и допълнете при нужда.", false)
      } else {
        this.setStatus("Фирмата не е намерена (или не е регистрирана по ДДС). Попълнете данните ръчно.", true)
      }
    } catch (e) {
      this.setStatus("Неуспешно свързване с регистъра. Попълнете данните ръчно.", true)
    } finally {
      this.lookupBtnTarget.disabled = false
    }
  }

  setStatus(text, isError) {
    this.statusTarget.textContent = text
    this.statusTarget.classList.toggle("is-error", !!isError)
  }
}
