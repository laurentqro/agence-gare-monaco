import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  toggle() {
    if (!this.hasMenuTarget) return
    const isOpen = !this.menuTarget.classList.contains("opacity-0")
    isOpen ? this.hide() : this.show()
  }

  show() {
    if (!this.hasMenuTarget) return
    this.menuTarget.classList.remove("opacity-0", "scale-y-0", "pointer-events-none")
    this.menuTarget.classList.add("opacity-100", "scale-y-100", "pointer-events-auto")
  }

  hide() {
    if (!this.hasMenuTarget) return
    this.menuTarget.classList.remove("opacity-100", "scale-y-100", "pointer-events-auto")
    this.menuTarget.classList.add("opacity-0", "scale-y-0", "pointer-events-none")
  }

  // Close dropdown when clicking outside
  close(event) {
    if (this.hasMenuTarget && !this.element.contains(event.target)) {
      this.hide()
    }
  }

  connect() {
    this._closeHandler = this.close.bind(this)
    document.addEventListener("click", this._closeHandler)
  }

  disconnect() {
    document.removeEventListener("click", this._closeHandler)
  }
}
