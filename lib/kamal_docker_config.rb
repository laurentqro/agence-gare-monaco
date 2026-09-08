require "fileutils"
require "open3"
require "yaml"

module KamalDockerConfig
  module_function

  def path(root)
    File.join(root, ".kamal", "docker")
  end

  def isolate!(root:, env: ENV)
    dir = path(root)
    FileUtils.mkdir_p(dir)
    env["DOCKER_CONFIG"] ||= dir
    dir
  end

  def login!(root:, env: ENV, runner: method(:docker_login))
    isolate!(root: root, env: env)
    registry = registry_from_deploy(root)
    runner.call(
      server: registry.fetch("server"),
      username: registry.fetch("username"),
      password: env.fetch("KAMAL_REGISTRY_PASSWORD"),
      docker_config: env.fetch("DOCKER_CONFIG")
    )
  end

  def registry_from_deploy(root)
    source = File.read(File.join(root, "config", "deploy.yml")).gsub(/<%.*?%>/m, "")
    YAML.safe_load(source).fetch("registry")
  end

  def docker_login(server:, username:, password:, docker_config:)
    output, status = Open3.capture2e(
      { "DOCKER_CONFIG" => docker_config },
      "docker", "login", server, "-u", username, "--password-stdin",
      stdin_data: password
    )
    raise "docker login #{server} as #{username} failed: #{output}" unless status.success?
  end
end
