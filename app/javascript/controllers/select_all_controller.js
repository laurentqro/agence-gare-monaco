import { Controller } from "@hotwired/stimulus"

// Stateless "select all" for the compose recipient list. The header checkbox
// toggles every CURRENTLY-LISTED row checkbox; the header reflects an
// all/none/indeterminate state as rows change. Because the list shows a single
// audience filtered by search, "select all" unambiguously means "everyone
// currently shown" — there is no cross-audience selection to persist (unlike
// the property-share picker). The controller lives OUTSIDE the Turbo Frame, so
// after the frame re-renders (audience/search change) it resyncs the header to
// whatever rows are now present.
export default class extends Controller {
  static targets = ["all", "item"]

  connect() {
    this.syncHeader()
  }

  // Header checkbox clicked: apply its state to every visible row.
  toggleAll() {
    const checked = this.allTarget.checked
    this.itemTargets.forEach((box) => { box.checked = checked })
  }

  // A row changed: refresh the header's checked/indeterminate state.
  itemChanged() {
    this.syncHeader()
  }

  // Re-run when Stimulus connects new item targets after a frame render.
  itemTargetConnected() {
    this.syncHeader()
  }

  itemTargetDisconnected() {
    this.syncHeader()
  }

  syncHeader() {
    if (!this.hasAllTarget) return
    const total = this.itemTargets.length
    const checked = this.itemTargets.filter((box) => box.checked).length
    this.allTarget.checked = total > 0 && checked === total
    this.allTarget.indeterminate = checked > 0 && checked < total
  }
}
