import { Controller } from "@hotwired/stimulus"

// Hover/touch tooltip for the price evolution sparkline.
// Each year emits enter/leave events with the year + price; we position the
// tooltip in viewBox coordinates and translate that into pixels using the
// rendered SVG bounding box.
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

    const rect = this.svgTarget.getBoundingClientRect()
    const vb = this.svgTarget.viewBox.baseVal
    const xPx = (cx / vb.width) * rect.width
    const yPx = (cy / vb.height) * rect.height

    this.tooltipTarget.style.left = `${xPx}px`
    this.tooltipTarget.style.top  = `${yPx}px`
    this.tooltipTarget.classList.remove("opacity-0")

    this.guideTarget.setAttribute("x1", cx)
    this.guideTarget.setAttribute("x2", cx)
    this.guideTarget.classList.remove("opacity-0")

    this.dotTarget.setAttribute("cx", cx)
    this.dotTarget.setAttribute("cy", cy)
    this.dotTarget.classList.remove("opacity-0")
  }

  hide() {
    this.tooltipTarget.classList.add("opacity-0")
    this.guideTarget.classList.add("opacity-0")
    this.dotTarget.classList.add("opacity-0")
  }
}
