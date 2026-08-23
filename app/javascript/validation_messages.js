// Bulgarian texts for the browser's native form-validation bubbles, which
// otherwise follow the visitor's browser language instead of the site's.
function bulgarianMessage(el) {
  const v = el.validity
  if (v.valueMissing) {
    if (el.type === "checkbox" || el.type === "radio") return "Моля, отметнете това поле."
    if (el.tagName === "SELECT") return "Моля, изберете опция от списъка."
    return "Моля, попълнете това поле."
  }
  if (v.typeMismatch && el.type === "email") return "Моля, въведете валиден имейл адрес."
  if (v.typeMismatch && el.type === "tel") return "Моля, въведете валиден телефонен номер."
  if (v.patternMismatch) return "Моля, спазвайте изисквания формат."
  if (v.rangeUnderflow) return `Стойността трябва да е поне ${el.min}.`
  if (v.rangeOverflow) return `Стойността трябва да е най-много ${el.max}.`
  if (v.stepMismatch) return "Моля, въведете валидна стойност."
  if (v.tooShort) return `Моля, въведете поне ${el.minLength} знака.`
  if (v.tooLong) return `Моля, въведете най-много ${el.maxLength} знака.`
  return ""
}

document.addEventListener("invalid", (event) => {
  const el = event.target
  if (typeof el.setCustomValidity !== "function") return
  el.setCustomValidity(bulgarianMessage(el))
}, true)

// Clear the custom message as soon as the value changes, otherwise the field
// would be stuck invalid even after the visitor fixes it.
for (const type of ["input", "change"]) {
  document.addEventListener(type, (event) => {
    const el = event.target
    if (typeof el.setCustomValidity === "function") el.setCustomValidity("")
  }, true)
}
