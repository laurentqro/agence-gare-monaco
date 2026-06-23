import { Controller } from "@hotwired/stimulus"

// Click-to-load YouTube facade: shows a cookie-free thumbnail until the user
// clicks, then swaps in the real (autoplaying) embed iframe. Keeps the live
// iframe — and its third-party cookies — off the initial page load.
export default class extends Controller {
  static values = { src: String, title: String }

  load() {
    const iframe = document.createElement("iframe")
    iframe.src = this.srcValue
    iframe.title = this.titleValue
    iframe.className = "w-full h-full"
    iframe.setAttribute("frameborder", "0")
    iframe.setAttribute("allowfullscreen", "")
    iframe.setAttribute(
      "allow",
      "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
    )
    this.element.replaceWith(iframe)
  }
}
