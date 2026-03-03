module MarkdownHelper
  def render_markdown(text)
    return "" if text.blank?

    html = Commonmarker.to_html(text, options: { extension: { table: true, autolink: true, strikethrough: true } })
    html.html_safe
  end
end
