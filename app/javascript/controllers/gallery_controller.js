import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["photo", "thumbnail"]

  connect() {
    this.currentIndex = 0
  }

  next() {
    this.goToIndex((this.currentIndex + 1) % this.photoTargets.length)
  }

  prev() {
    this.goToIndex((this.currentIndex - 1 + this.photoTargets.length) % this.photoTargets.length)
  }

  goTo(event) {
    const index = parseInt(event.params.index, 10)
    this.goToIndex(index)
  }

  goToIndex(index) {
    this.photoTargets.forEach((photo, i) => {
      photo.classList.toggle("opacity-100", i === index)
      photo.classList.toggle("opacity-0", i !== index)
    })

    this.thumbnailTargets.forEach((thumb, i) => {
      thumb.classList.toggle("border-[#090956]", i === index)
      thumb.classList.toggle("border-transparent", i !== index)
    })

    this.currentIndex = index
  }
}
