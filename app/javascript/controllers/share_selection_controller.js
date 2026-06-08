import { Controller } from "@hotwired/stimulus"

// Preserves which contacts are checked across Turbo Frame re-renders (sorting).
// The controller lives on a wrapper OUTSIDE the sortable frame, so it survives
// the swap. It records every checkbox toggle, then re-applies the saved set
// after the frame renders new rows.
//
// Markup:
//   <div data-controller="share-selection">
//     <turbo-frame id="share_contacts_table"> ...checkboxes... </turbo-frame>
//   </div>
export default class extends Controller {
  connect() {
    this.selected = new Set()
    this.captureCurrent()

    this.onChange = this.onChange.bind(this)
    this.onFrameRender = this.onFrameRender.bind(this)

    this.element.addEventListener("change", this.onChange)
    this.element.addEventListener("turbo:frame-render", this.onFrameRender)
  }

  disconnect() {
    this.element.removeEventListener("change", this.onChange)
    this.element.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  onChange(event) {
    const box = event.target
    if (!this.isContactCheckbox(box)) return

    if (box.checked) {
      this.selected.add(box.value)
    } else {
      this.selected.delete(box.value)
    }
  }

  // After Turbo swaps in the re-sorted rows, re-check anything still selected.
  onFrameRender() {
    this.checkboxes().forEach((box) => {
      box.checked = this.selected.has(box.value)
    })
  }

  // Seed state from whatever is checked on initial render.
  captureCurrent() {
    this.checkboxes().forEach((box) => {
      if (box.checked) this.selected.add(box.value)
    })
  }

  checkboxes() {
    return this.element.querySelectorAll('input[type="checkbox"][name="contact_ids[]"]')
  }

  isContactCheckbox(el) {
    return (
      el.matches &&
      el.matches('input[type="checkbox"][name="contact_ids[]"]')
    )
  }
}
