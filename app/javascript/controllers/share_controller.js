import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["copyLabel"]
  static values = { url: String, title: String, text: String, copiedLabel: String }

  connect() {
    this.defaultCopyLabel = this.hasCopyLabelTarget ? this.copyLabelTarget.textContent : ""
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
    clearTimeout(this.resetLabelTimer)
  }

  openNativeSheet(event) {
    if (!this.nativeSheetPreferred) return

    event.preventDefault()
    navigator.share({ title: this.titleValue, text: this.textValue, url: this.urlValue }).catch(() => {})
  }

  async copyLink() {
    if (!(await this.writeToClipboard(this.urlValue))) return

    this.copyLabelTarget.textContent = this.copiedLabelValue
    clearTimeout(this.resetLabelTimer)
    this.resetLabelTimer = setTimeout(() => {
      this.copyLabelTarget.textContent = this.defaultCopyLabel
    }, 2500)
  }

  close() {
    this.element.open = false
  }

  closeOnClickOutside(event) {
    if (this.element.open && !this.element.contains(event.target)) this.close()
  }

  get nativeSheetPreferred() {
    return typeof navigator.share === "function" && window.matchMedia("(pointer: coarse)").matches
  }

  async writeToClipboard(text) {
    try {
      await navigator.clipboard.writeText(text)
      return true
    } catch {
      return this.copyViaHiddenField(text)
    }
  }

  copyViaHiddenField(text) {
    const field = document.createElement("textarea")
    field.value = text
    field.setAttribute("readonly", "")
    field.style.position = "fixed"
    field.style.opacity = "0"
    document.body.appendChild(field)
    field.select()
    const copied = document.execCommand("copy")
    field.remove()
    return copied
  }
}
