require "digest"
require "rack/utils"
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

    entries = Rack::Utils.q_values(accept)
    markdown = preference_for(MARKDOWN, entries)
    html = preference_for(HTML, entries)
    return false unless markdown&.acceptable?
    return true unless html&.acceptable?

    markdown > html
  end

  def self.preference_for(type, entries)
    entries.each_with_index.filter_map do |(candidate, quality), position|
      specificity = specificity_of(candidate.downcase.split(";").first.strip, type)
      Preference.new(quality, specificity, position) if specificity
    end.max
  end

  def self.specificity_of(candidate, type)
    return 2 if candidate == type
    return 1 if candidate == "#{type.split('/').first}/*"
    0 if candidate == "*/*"
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    return @app.call(env) unless negotiable?(env)

    wants_markdown = self.class.prefers_markdown?(env["HTTP_ACCEPT"])
    env["HTTP_ACCEPT"] = HTML if wants_markdown

    status, headers, body = @app.call(env)
    return [ status, headers, body ] unless html?(headers)

    headers = vary_on_accept(headers)
    return [ status, headers, body ] unless wants_markdown

    render_markdown(env, status, headers, body)
  end

  private

  def negotiable?(env)
    %w[GET HEAD].include?(env["REQUEST_METHOD"])
  end

  def html?(headers)
    headers["content-type"].to_s.downcase.start_with?(HTML)
  end

  def vary_on_accept(headers)
    values = headers["vary"].to_s.split(",").map(&:strip).reject(&:empty?)
    values << "Accept" unless values.any? { |value| value.casecmp?("Accept") }
    headers.merge("vary" => values.join(", "))
  end

  def render_markdown(env, status, headers, body)
    html = +""
    body.each { |chunk| html << chunk }
    body.close if body.respond_to?(:close)

    headers = headers.merge("content-type" => MARKDOWN_CONTENT_TYPE)
    return [ status, headers.except("content-length", "etag"), [] ] if html.empty?

    markdown = HtmlToMarkdown.convert(html, base_url: base_url(env))
    headers = headers.merge("content-length" => markdown.bytesize.to_s, "etag" => %(W/"#{Digest::SHA256.hexdigest(markdown)[0, 32]}"))
    [ status, headers, [ markdown ] ]
  end

  def base_url(env)
    request = Rack::Request.new(env)
    "#{request.scheme}://#{request.host_with_port}"
  end
end
