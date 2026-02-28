class TrailingSlashRedirector
  def initialize(app)
    @app = app
  end

  def call(env)
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
