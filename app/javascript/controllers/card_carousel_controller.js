import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]

  connect() {
    this.currentIndex = 0
  }

  next(event) {
    event.preventDefault()
    event.stopPropagation()
    this.goToIndex((this.currentIndex + 1) % this.slideTargets.length)
  }

  prev(event) {
    event.preventDefault()
    event.stopPropagation()
    this.goToIndex((this.currentIndex - 1 + this.slideTargets.length) % this.slideTargets.length)
  }

  goToIndex(index) {
    this.slideTargets.forEach((slide, i) => {
      slide.classList.toggle("opacity-100", i === index)
      slide.classList.toggle("opacity-0", i !== index)
    })
    this.currentIndex = index
  }
}
