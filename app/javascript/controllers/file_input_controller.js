import { Controller } from "@hotwired/stimulus"

// Styles the native file input: the real <input type="file"> is hidden and a
// themed label-button triggers it, while this controller mirrors the chosen
// file's name (or a French "no file" placeholder) into a display element.
//
// Markup:
//   <div data-controller="file-input" data-file-input-empty-value="Aucun fichier sélectionné">
//     <label>…<input type="file" class="hidden" data-action="change->file-input#changed"></label>
//     <span data-file-input-target="filename">Aucun fichier sélectionné</span>
//   </div>
export default class extends Controller {
  static targets = ["filename"]
  static values = { empty: String }

  changed(event) {
    const input = event.target
    const name = input.files && input.files.length ? input.files[0].name : this.emptyValue
    if (this.hasFilenameTarget) this.filenameTarget.textContent = name
  }
}
