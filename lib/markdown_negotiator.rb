require "digest"
require_relative "html_to_markdown"

class MarkdownNegotiator
  HTML = "text/html".freeze
  MARKDOWN = "text/markdown".freeze
  MARKDOWN_CONTENT_TYPE = "text/markdown; charset=utf-8".freeze

  Preference = Struct.new(:quality, :specificity, :position) do
    include Comparable

    def acceptable?
      quality.positive?
    end

    def <=>(other)
      [ quality, specificity, -position ] <=> [ other.quality, other.specificity, -other.position ]
    end
  end

  def self.prefers_markdown?(accept)
    return false if accept.blank?

    entries = parse_accept(accept)
    markdown = preference_for(MARKDOWN, entries)
    html = preference_for(HTML, entries)
    return false unless markdown&.acceptable?
    return true unless html&.acceptable?

    markdown > html
  end

  def self.parse_accept(accept)
    accept.split(",").filter_map do |element|
      media_type, *parameters = element.split(";").map(&:strip)
      next if media_type.blank?

      quality = parameters.find { |parameter| parameter.start_with?("q=") }&.delete_prefix("q=")
      [ media_type.downcase, quality ? quality.to_f.clamp(0.0, 1.0) : 1.0 ]
    end
  end

  def self.preference_for(type, entries)
    entries.each_with_index.filter_map do |(candidate, quality), position|
      specificity = specificity_of(candidate, type)
      Preference.new(quality, specificity, position) if specificity
    end.max_by { |preference| [ preference.specificity, preference.quality, -preference.position ] }
  end

  def self.specificity_of(candidate, type)
    return 2 if candidate == type
    return 1 if candidate == "#{type.split('/').first}/*"
    0 if candidate == "*/*"
  end

  def initialize(app, base_url:)
    @app = app
    @base_url = base_url
  end

  def call(env)
    return @app.call(env) unless negotiable?(env)

    wants_markdown = self.class.prefers_markdown?(env["HTTP_ACCEPT"])
    return pass_through(env) unless wants_markdown

    head = env["REQUEST_METHOD"] == "HEAD"
    env["HTTP_ACCEPT"] = HTML
    env["REQUEST_METHOD"] = "GET" if head

    status, headers, body = @app.call(env)
    if html?(headers)
      status, headers, body = render_markdown(env, status, vary_on_accept(headers), body)
    end

    if head
      body.close if body.respond_to?(:close)
      body = []
    end

    [ status, headers, body ]
  end

  private

  def negotiable?(env)
    %w[GET HEAD].include?(env["REQUEST_METHOD"])
  end

  def pass_through(env)
    status, headers, body = @app.call(env)
    html?(headers) ? [ status, vary_on_accept(headers), body ] : [ status, headers, body ]
  end

  def html?(headers)
    headers["content-type"].to_s.downcase.start_with?(HTML)
  end

  def vary_on_accept(headers)
    values = headers["vary"].to_s.split(",").map(&:strip).reject(&:empty?)
    values << "Accept" unless values.any? { |value| value.casecmp?("Accept") }
    headers.merge("vary" => values.join(", "))
  end

  def render_markdown(env, status, html_headers, body)
    html = +""
    body.each { |chunk| html << chunk }
    body.close if body.respond_to?(:close)

    markdown = HtmlToMarkdown.convert(html, base_url: @base_url)
    etag = %(W/"#{Digest::SHA256.hexdigest(markdown)[0, 32]}")
    headers = html_headers.merge("content-type" => MARKDOWN_CONTENT_TYPE, "content-length" => markdown.bytesize.to_s, "etag" => etag)
    return [ 304, headers.except("content-type", "content-length"), [] ] if env["HTTP_IF_NONE_MATCH"] == etag

    [ status, headers, [ markdown ] ]
  rescue StandardError => error
    Rails.logger.warn("MarkdownNegotiator fell back to HTML: #{error.class}: #{error.message}") if defined?(Rails)
    [ status, html_headers.merge("content-length" => html.bytesize.to_s), [ html ] ]
  end
end
