import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]

  connect() {
    this.currentIndex = 0
    this.totalSlides = this.trackTarget.children.length
  }

  next() {
    this.currentIndex = (this.currentIndex + 1) % this.totalSlides
    this.updatePosition()
  }

  prev() {
    this.currentIndex = (this.currentIndex - 1 + this.totalSlides) % this.totalSlides
    this.updatePosition()
  }

  updatePosition() {
    const offset = -this.currentIndex * 100
    this.trackTarget.style.transform = `translateX(${offset}%)`
  }
}
