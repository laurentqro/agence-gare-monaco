import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "label", "dropdown"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.closeOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    this.dropdownTarget.classList.toggle("hidden")
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.add("hidden")
    }
  }

  changed() {
    this.element.closest("form").requestSubmit()
  }
}
