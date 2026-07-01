import { Controller } from "@hotwired/stimulus"

// Drives the compose recipient picker. It lives OUTSIDE the Turbo Frame so it
// survives the frame swap that happens on an audience toggle or a search, and
// it keeps three things consistent across those swaps:
//
//   1. Selection persistence. Checked recipients are recorded in a Set keyed by
//      contact id and re-applied after every frame render, so checking peers,
//      then searching for one more, does not silently drop the first picks.
//   2. The audience hidden field. Each re-rendered frame advertises its current
//      audience via data-audience; the controller copies that into the hidden
//      field the main form submits, so the audience the server filters by always
//      matches the audience the user is looking at.
//   3. Select-all. The header checkbox toggles every currently-listed row, and
//      reflects an all/none/indeterminate state as rows change.
//
// Markup:
//   <div data-controller="recipient-selection">
//     <input type="hidden" id="compose_audience" ...>
//     <turbo-frame id="compose_recipients" data-audience="peers"> ...rows... </turbo-frame>
//   </div>
export default class extends Controller {
  static targets = ["all", "audience"]

  connect() {
    this.selected = new Set()
    this.captureChecked()

    this.onChange = this.onChange.bind(this)
    this.onFrameRender = this.onFrameRender.bind(this)
    this.element.addEventListener("change", this.onChange)
    this.element.addEventListener("turbo:frame-render", this.onFrameRender)

    this.syncAudience()
    this.syncHeader()
  }

  disconnect() {
    this.element.removeEventListener("change", this.onChange)
    this.element.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  // Header "select all" clicked: apply its state to every visible row, recording
  // each into the persistent Set so the choice survives the next frame render.
  toggleAll() {
    const checked = this.allTarget.checked
    this.itemCheckboxes().forEach((box) => {
      box.checked = checked
      this.record(box)
    })
    this.syncHeader()
  }

  onChange(event) {
    const box = event.target
    if (!this.isItem(box)) return
    this.record(box)
    this.syncHeader()
  }

  // After Turbo swaps in new rows (audience/search change), re-check anything
  // still selected and resync the audience field + header to the new rows.
  onFrameRender() {
    this.itemCheckboxes().forEach((box) => {
      box.checked = this.selected.has(box.value)
    })
    this.syncAudience()
    this.syncHeader()
  }

  // Seed the Set from whatever is checked on the initial render.
  captureChecked() {
    this.itemCheckboxes().forEach((box) => {
      if (box.checked) this.selected.add(box.value)
    })
  }

  record(box) {
    if (box.checked) {
      this.selected.add(box.value)
    } else {
      this.selected.delete(box.value)
    }
  }

  // Mirror the frame's current audience into the hidden field the form submits.
  syncAudience() {
    if (!this.hasAudienceTarget) return
    const frame = this.element.querySelector("turbo-frame#compose_recipients")
    const audience = frame && frame.getAttribute("data-audience")
    if (audience) this.audienceTarget.value = audience
  }

  syncHeader() {
    if (!this.hasAllTarget) return
    const boxes = this.itemCheckboxes()
    const total = boxes.length
    const checked = boxes.filter((box) => box.checked).length
    this.allTarget.checked = total > 0 && checked === total
    this.allTarget.indeterminate = checked > 0 && checked < total
  }

  itemCheckboxes() {
    return Array.from(
      this.element.querySelectorAll('input[type="checkbox"][name="contact_ids[]"]')
    )
  }

  isItem(el) {
    return el.matches && el.matches('input[type="checkbox"][name="contact_ids[]"]')
  }
}
