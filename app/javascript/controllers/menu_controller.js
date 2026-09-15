import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.closeOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.closeOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside)
  }

  close() {
    this.element.open = false
  }

  closeOnClickOutside(event) {
    if (this.element.open && !this.element.contains(event.target)) this.close()
  }
}
