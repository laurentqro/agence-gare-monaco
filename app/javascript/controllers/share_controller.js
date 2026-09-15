import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["copyLabel"]
  static values = { url: String, title: String, text: String, copiedLabel: String }

  connect() {
    this.defaultCopyLabel = this.hasCopyLabelTarget ? this.copyLabelTarget.textContent : ""
  }

  disconnect() {
    clearTimeout(this.resetLabelTimer)
  }

  openNativeSheet(event) {
    if (this.element.open || !this.nativeSheetPreferred) return

    event.preventDefault()
    if (this.sharing) return

    this.sharing = navigator.share(this.shareData)
      .catch((error) => {
        if (error?.name !== "AbortError") this.element.open = true
      })
      .finally(() => {
        this.sharing = null
      })
  }

  async copyLink() {
    if (!(await this.writeToClipboard(this.urlValue))) return

    this.copyLabelTarget.textContent = this.copiedLabelValue
    clearTimeout(this.resetLabelTimer)
    this.resetLabelTimer = setTimeout(() => {
      this.copyLabelTarget.textContent = this.defaultCopyLabel
    }, 2500)
  }

  get shareData() {
    return { title: this.titleValue, text: this.textValue, url: this.urlValue }
  }

  get nativeSheetPreferred() {
    return this.touchDevice && this.deviceCanShare
  }

  get touchDevice() {
    return window.matchMedia("(pointer: coarse)").matches
  }

  get deviceCanShare() {
    if (typeof navigator.share !== "function") return false
    if (typeof navigator.canShare !== "function") return true

    return navigator.canShare(this.shareData)
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
