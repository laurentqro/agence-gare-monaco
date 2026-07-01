class TrailingSlashRedirector
  def initialize(app)
    @app = app
  end

  # Only the production apex is canonicalised; other hosts (test's
  # www.example.com, the tailnet IP, health checks) pass through untouched.
  WWW_HOST = "www.agencegaremonaco.com".freeze
  APEX_HOST = "agencegaremonaco.com".freeze

  def call(env)
    # Redirect www → bare apex (single canonical host). Always land on https so a
    # www-over-http request takes one hop, not two.
    if env["HTTP_HOST"].to_s == WWW_HOST
      query = env["QUERY_STRING"]
      location = "https://#{APEX_HOST}#{env["PATH_INFO"]}"
      location = "#{location}?#{query}" if query.present?
      return [ 301, { "Location" => location, "Content-Type" => "text/html" }, [ "" ] ]
    end

    path = env["PATH_INFO"]

    # Redirect paths with trailing slashes (except root "/")
    if path != "/" && path.end_with?("/")
      new_path = path.chomp("/")
      query = env["QUERY_STRING"]
      location = query.present? ? "#{new_path}?#{query}" : new_path
      [ 301, { "Location" => location, "Content-Type" => "text/html" }, [ "" ] ]
    else
      @app.call(env)
    end
  end
end
