module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    # header_ids: nil disables Commonmarker's auto-generated heading anchors,
    # which are emitted as aria-hidden focusable links (fails aria-hidden-focus).
    html = Commonmarker.to_html(text, options: { extension: { table: true, autolink: true, strikethrough: true, header_ids: nil } })
    html.html_safe
  end
end
