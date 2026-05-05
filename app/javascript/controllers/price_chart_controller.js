import { Controller } from "@hotwired/stimulus"

// Hover/touch tooltip for the price evolution sparkline.
// Positions a tooltip above the active data point, clamped horizontally
// so it never clips past the chart's edges.
export default class extends Controller {
  static targets = ["svg", "tooltip", "tooltipYear", "tooltipPrice", "guide", "dot"]

  show(event) {
    const t = event.currentTarget
    const cx = parseFloat(t.dataset.cx)
    const cy = parseFloat(t.dataset.cy)
    const year = t.dataset.year
    const price = t.dataset.price

    this.tooltipYearTarget.textContent = year
    this.tooltipPriceTarget.textContent = price

    // Move guide + dot first (these live in viewBox coords).
    this.guideTarget.setAttribute("x1", cx)
    this.guideTarget.setAttribute("x2", cx)
    this.guideTarget.classList.remove("opacity-0")

    this.dotTarget.setAttribute("cx", cx)
    this.dotTarget.setAttribute("cy", cy)
    this.dotTarget.classList.remove("opacity-0")

    // Show first so we can measure tooltip width, then position.
    this.tooltipTarget.classList.remove("opacity-0")

    const rect = this.svgTarget.getBoundingClientRect()
    const vb = this.svgTarget.viewBox.baseVal
    const xPx = (cx / vb.width) * rect.width
    const yPx = (cy / vb.height) * rect.height

    const tipW = this.tooltipTarget.offsetWidth
    const tipH = this.tooltipTarget.offsetHeight
    const margin = 24 // breathing room from chart edges

    // Clamp horizontally: ideal is cursor-centered, but never spill past edges.
    let left = xPx - tipW / 2
    if (left < margin) left = margin
    if (left + tipW > rect.width - margin) left = rect.width - tipW - margin

    // Vertical: prefer above the dot; if not enough room, place below.
    let top = yPx - tipH - 14
    if (top < margin) top = yPx + 14

    this.tooltipTarget.style.left = `${left}px`
    this.tooltipTarget.style.top  = `${top}px`
  }

  hide() {
    this.tooltipTarget.classList.add("opacity-0")
    this.guideTarget.classList.add("opacity-0")
    this.dotTarget.classList.add("opacity-0")
  }
}
