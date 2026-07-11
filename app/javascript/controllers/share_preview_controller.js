import { Controller } from "@hotwired/stimulus"

// Live email preview for the property share page: as the admin types the
// personal note, the preview iframe re-renders the actual mailer output. The
// server does the rendering (same template as the real email), so the preview
// never drifts from what gets sent; this controller just debounces the
// keystrokes, POSTs the draft note, and swaps the iframe's srcdoc with the
// response.
export default class extends Controller {
  static targets = ["source", "frame"]
  static values = { url: String, delay: { type: Number, default: 400 } }

  disconnect() {
    clearTimeout(this.timer)
    this.abortController?.abort()
  }

  changed() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.refresh(), this.delayValue)
  }

  async refresh() {
    // A slow response must never overwrite a newer one: abort any in-flight
    // request before starting the next.
    this.abortController?.abort()
    this.abortController = new AbortController()

    const body = new FormData()
    body.append("body", this.sourceTarget.value)

    let response
    try {
      response = await fetch(this.urlValue, {
        method: "POST",
        headers: { "X-CSRF-Token": this.csrfToken },
        body,
        signal: this.abortController.signal
      })
    } catch {
      return // aborted or offline: keep the last good preview
    }
    if (!response.ok) return

    this.frameTarget.srcdoc = await response.text()
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
