require "nokogiri"
require "reverse_markdown"

module HtmlToMarkdown
  NOISE = "script, style, svg, noscript, template, form, iframe, [aria-hidden='true'], [hidden]".freeze
  HARD_BREAK = "  ".freeze

  def self.convert(html, base_url:)
    document = Nokogiri::HTML5(html)
    content = document.at_css("main") || document.at_css("body")
    content.css(NOISE).each(&:remove)
    content.css("a").select { |a| a.text.blank? && a.at_css("img").nil? }.each(&:remove)
    unwrap_details(content)
    absolutise(content, base_url)
    markdown = ReverseMarkdown.convert(content.inner_html, github_flavored: true, unknown_tags: :bypass)
    with_title(tidy(markdown), document, content)
  end

  def self.unwrap_details(node)
    node.css("summary").each { |summary| summary.replace("<p><strong>#{summary.inner_html}</strong></p>") }
    node.css("details").each { |details| details.replace(details.children) }
  end

  def self.absolutise(node, base_url)
    node.css("a[href]").each { |a| a["href"] = absolute_url(base_url, a["href"]) }
    node.css("img[src]").each { |img| img["src"] = absolute_url(base_url, img["src"]) }
  end

  def self.absolute_url(base_url, url)
    URI.join(base_url, url).to_s
  rescue URI::Error
    URI.join(base_url, URI::RFC2396_PARSER.escape(url)).to_s
  end

  def self.tidy(markdown)
    lines = markdown.lines.map { |line| line.end_with?("#{HARD_BREAK}\n") ? line.rstrip + HARD_BREAK : line.rstrip }
    lines.join("\n").gsub(/\n{3,}/, "\n\n").strip
  end

  def self.with_title(markdown, document, content)
    title = document.at_css("title")&.text&.squish
    return markdown if title.blank? || content.at_css("h1")

    [ "# #{title}", markdown ].reject(&:empty?).join("\n\n")
  end
end
