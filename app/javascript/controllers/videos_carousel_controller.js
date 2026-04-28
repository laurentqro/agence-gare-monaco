import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track", "slide", "prevButton", "nextButton"]

  connect() {
    this.currentIndex = 0
    this.updateVisibleCount()
    this.updateButtonVisibility()
    this.boundResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundResize)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundResize)
  }

  handleResize() {
    this.updateVisibleCount()
    this.clampIndex()
    this.updatePosition()
    this.updateButtonVisibility()
  }

  updateButtonVisibility() {
    const show = this.maxIndex() > 0
    if (this.hasPrevButtonTarget) this.prevButtonTarget.classList.toggle("hidden", !show)
    if (this.hasNextButtonTarget) this.nextButtonTarget.classList.toggle("hidden", !show)
  }

  updateVisibleCount() {
    const w = window.innerWidth
    if (w >= 768) {
      this.visibleCount = 3
    } else {
      this.visibleCount = 1
    }
  }

  maxIndex() {
    return Math.max(0, this.slideTargets.length - this.visibleCount)
  }

  clampIndex() {
    if (this.currentIndex > this.maxIndex()) this.currentIndex = this.maxIndex()
    if (this.currentIndex < 0) this.currentIndex = 0
  }

  next(event) {
    if (event) { event.preventDefault(); event.stopPropagation() }
    if (this.currentIndex < this.maxIndex()) {
      this.currentIndex += 1
    } else {
      this.currentIndex = 0
    }
    this.updatePosition()
  }

  prev(event) {
    if (event) { event.preventDefault(); event.stopPropagation() }
    if (this.currentIndex > 0) {
      this.currentIndex -= 1
    } else {
      this.currentIndex = this.maxIndex()
    }
    this.updatePosition()
  }

  updatePosition() {
    const offset = -this.currentIndex * (100 / this.visibleCount)
    this.trackTarget.style.transform = `translateX(${offset}%)`
  }
}
