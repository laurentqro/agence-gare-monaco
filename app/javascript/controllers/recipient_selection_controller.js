import { Controller } from "@hotwired/stimulus"

// Drives the compose recipient picker, which stacks one list per audience
// (peers, owners, tenants, contacts) so a single email can target a mixed
// audience. The controller lives OUTSIDE the Turbo Frames so it survives the
// frame swap a per-list search triggers, and it keeps three things consistent
// across those swaps:
//
//   1. Selection persistence. Checked recipients are recorded in a Map keyed by
//      contact id (value = {name, audience}) and re-applied after every frame
//      render, so checking a peer, then searching the contacts list, does not
//      drop the peer. The Map also lets a chip render for a recipient whose row
//      was filtered out of the DOM by a search (the row's checkbox is gone, but
//      we still know its name and audience).
//   2. The live "selected" chip panels. Each audience has its own panel; the
//      controller renders one removable chip per selected recipient of that
//      audience. Clicking a chip's ✕ deselects that recipient everywhere.
//   3. Select-all, per list. Each list's header checkbox toggles that list's
//      currently-listed rows and reflects an all/none/indeterminate state.
//
// Everything is keyed by data-audience, so audiences are defined by the markup
// alone (RecipientLoading::AUDIENCES server-side), not by this controller.
//
// Markup (abbreviated, one pair per audience):
//   <div data-controller="recipient-selection">
//     <turbo-frame id="compose_peers"> ...rows (checkbox[data-audience=peers])... </turbo-frame>
//     <div data-recipient-selection-target="selected" data-audience="peers"></div>
//     ...
//   </div>
export default class extends Controller {
  static targets = ["all", "item", "selected"]

  connect() {
    // id -> { name, audience }. Preserved across frame renders.
    this.selected = new Map()
    this.captureChecked()

    this.onChange = this.onChange.bind(this)
    this.onClick = this.onClick.bind(this)
    this.onFrameRender = this.onFrameRender.bind(this)
    this.element.addEventListener("change", this.onChange)
    this.element.addEventListener("click", this.onClick)
    this.element.addEventListener("turbo:frame-render", this.onFrameRender)

    this.syncHeaders()
    this.renderChips()
  }

  disconnect() {
    this.element.removeEventListener("change", this.onChange)
    this.element.removeEventListener("click", this.onClick)
    this.element.removeEventListener("turbo:frame-render", this.onFrameRender)
  }

  // Header "select all" clicked: apply its state to every visible row of THAT
  // list, recording each into the Map so the choice survives the next render.
  toggleAll(event) {
    const header = event.target
    const audience = header.dataset.audience
    const checked = header.checked
    this.itemsForAudience(audience).forEach((box) => {
      box.checked = checked
      this.record(box)
    })
    this.syncHeaders()
    this.renderChips()
  }

  onChange(event) {
    const box = event.target
    if (!this.isItem(box)) return
    this.record(box)
    this.syncHeaders()
    this.renderChips()
  }

  // Chip ✕ clicked: deselect that recipient. Unchecks its row if still listed,
  // drops it from the Map, and refreshes headers + chips.
  onClick(event) {
    const remove = event.target.closest("[data-recipient-remove]")
    if (!remove || !this.element.contains(remove)) return
    event.preventDefault()

    const id = remove.dataset.recipientRemove
    this.selected.delete(id)
    const box = this.itemTargets.find((el) => el.value === id)
    if (box) box.checked = false
    this.syncHeaders()
    this.renderChips()
  }

  // After Turbo swaps in new rows (a per-list search), re-check anything still
  // selected and resync headers + chips to the new rows.
  onFrameRender() {
    this.itemTargets.forEach((box) => {
      box.checked = this.selected.has(box.value)
    })
    this.syncHeaders()
    this.renderChips()
  }

  // Seed the Map from whatever is checked on the initial render.
  captureChecked() {
    this.itemTargets.forEach((box) => {
      if (box.checked) this.record(box)
    })
  }

  record(box) {
    if (box.checked) {
      this.selected.set(box.value, {
        name: box.dataset.recipientName || "",
        audience: box.dataset.audience
      })
    } else {
      this.selected.delete(box.value)
    }
  }

  // Rebuild every chip panel from the Map, one chip per selected recipient in
  // the panel's audience. A chip carries the id so its ✕ can deselect it.
  renderChips() {
    this.selectedTargets.forEach((panel) => this.renderPanel(panel.dataset.audience, panel))
  }

  renderPanel(audience, panel) {
    panel.replaceChildren()
    this.selected.forEach((meta, id) => {
      if (meta.audience !== audience) return
      panel.appendChild(this.buildChip(id, meta.name))
    })
  }

  buildChip(id, name) {
    const chip = document.createElement("span")
    chip.className =
      "inline-flex items-center gap-1.5 rounded-full bg-navy/10 text-navy text-sm px-3 py-1"

    const label = document.createElement("span")
    label.textContent = name
    chip.appendChild(label)

    const remove = document.createElement("button")
    remove.type = "button"
    remove.dataset.recipientRemove = id
    remove.setAttribute("aria-label", `${this.removeLabel} ${name}`.trim())
    remove.className = "text-navy/60 hover:text-navy font-bold leading-none"
    remove.textContent = "×"
    chip.appendChild(remove)

    return chip
  }

  get removeLabel() {
    return this.element.dataset.recipientSelectionRemoveLabel || "Retirer"
  }

  // Reflect each list's all/none/indeterminate state independently.
  syncHeaders() {
    this.allTargets.forEach((header) => {
      const boxes = this.itemsForAudience(header.dataset.audience)
      const total = boxes.length
      const checked = boxes.filter((box) => box.checked).length
      header.checked = total > 0 && checked === total
      header.indeterminate = checked > 0 && checked < total
    })
  }

  itemsForAudience(audience) {
    return this.itemTargets.filter((box) => box.dataset.audience === audience)
  }

  isItem(el) {
    return el.matches && el.matches('input[type="checkbox"][name="contact_ids[]"]')
  }
}
