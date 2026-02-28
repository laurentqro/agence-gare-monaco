require "net/http"
require "json"
require "uri"

class ImmotoolboxClient
  class ApiError < StandardError; end

  BASE_URL = "https://clientapi.immotoolbox.com/api"

  def initialize(api_token:)
    raise ArgumentError, "api_token is required" if api_token.blank?
    @api_token = api_token
  end

  def fetch_districts
    get("/districts")
  end

  def fetch_buildings
    get("/buildings")
  end

  def fetch_properties(page: 1)
    get("/properties", status: "published", page: page.to_s)
  end

  def fetch_all_properties
    all = []
    page = 1

    loop do
      batch = fetch_properties(page: page)
      break if batch.empty?
      all.concat(batch)
      page += 1
    end

    all
  end

  def fetch_property(id)
    get("/properties/#{id}")
  end

  def fetch_images(property_id:)
    get("/images", property: property_id.to_s)
  end

  def fetch_texts(property_id:)
    get("/texts", property: property_id.to_s)
  end

  private

  def get(path, **params)
    uri = URI("#{BASE_URL}#{path}")
    uri.query = URI.encode_www_form(params) if params.any?

    request = Net::HTTP::Get.new(uri)
    request["X-AUTH-TOKEN"] = @api_token
    request["Accept"] = "application/json"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.open_timeout = 10
      http.read_timeout = 30
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise ApiError, "HTTP #{response.code}: #{response.body}"
    end

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError => e
    raise ApiError, "Network error: #{e.message}"
  end
end
