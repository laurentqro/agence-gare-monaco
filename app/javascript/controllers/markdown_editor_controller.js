import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "preview", "writeTab", "previewTab", "toolbar", "fileInput"]
  static values = { previewUrl: String }

  connect() {
    this.showWrite()
  }

  // Tab switching
  showWrite() {
    this.textareaTarget.classList.remove("hidden")
    this.previewTarget.classList.add("hidden")
    this.writeTabTarget.classList.add("border-[#090956]", "text-[#090956]")
    this.writeTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.previewTabTarget.classList.add("border-transparent", "text-gray-500")
    this.previewTabTarget.classList.remove("border-[#090956]", "text-[#090956]")
  }

  showPreview() {
    this.textareaTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.previewTabTarget.classList.add("border-[#090956]", "text-[#090956]")
    this.previewTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.writeTabTarget.classList.add("border-transparent", "text-gray-500")
    this.writeTabTarget.classList.remove("border-[#090956]", "text-[#090956]")

    this.fetchPreview()
  }

  async fetchPreview() {
    const body = this.textareaTarget.value
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    const response = await fetch(this.previewUrlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Accept": "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken
      },
      body: new URLSearchParams({ body })
    })

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    }
  }

  // Toolbar actions
  bold() {
    this.wrapSelection("**", "**")
  }

  italic() {
    this.wrapSelection("_", "_")
  }

  heading2() {
    this.prefixLine("## ")
  }

  heading3() {
    this.prefixLine("### ")
  }

  link() {
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const selectedText = textarea.value.substring(start, end)

    if (selectedText) {
      this.insertText(`[${selectedText}](url)`, start, end)
      // Position cursor on "url"
      textarea.focus()
      textarea.setSelectionRange(start + selectedText.length + 3, start + selectedText.length + 6)
    } else {
      this.insertText("[text](url)", start, end)
      textarea.focus()
      textarea.setSelectionRange(start + 1, start + 5)
    }
  }

  bulletList() {
    this.prefixLine("- ")
  }

  numberedList() {
    this.prefixLine("1. ")
  }

  quote() {
    this.prefixLine("> ")
  }

  image() {
    this.fileInputTarget.click()
  }

  imageSelected() {
    const file = this.fileInputTarget.files[0]
    if (file) {
      const textarea = this.textareaTarget
      const pos = textarea.selectionStart
      this.insertText(`![${file.name}](url)`, pos, pos)
      textarea.focus()
    }
    // Reset file input for re-selection
    this.fileInputTarget.value = ""
  }

  // Helpers
  wrapSelection(before, after) {
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const end = textarea.selectionEnd
    const selectedText = textarea.value.substring(start, end)

    if (selectedText) {
      this.insertText(`${before}${selectedText}${after}`, start, end)
      textarea.focus()
      textarea.setSelectionRange(start + before.length, end + before.length)
    } else {
      this.insertText(`${before}text${after}`, start, end)
      textarea.focus()
      textarea.setSelectionRange(start + before.length, start + before.length + 4)
    }
  }

  prefixLine(prefix) {
    const textarea = this.textareaTarget
    const start = textarea.selectionStart
    const value = textarea.value

    // Find the beginning of the current line
    const lineStart = value.lastIndexOf("\n", start - 1) + 1

    this.insertText(prefix, lineStart, lineStart)
    textarea.focus()
    textarea.setSelectionRange(start + prefix.length, start + prefix.length)
  }

  insertText(text, start, end) {
    const textarea = this.textareaTarget
    const before = textarea.value.substring(0, start)
    const after = textarea.value.substring(end)
    textarea.value = before + text + after
  }
}
