require "test_helper"
require "kamal_docker_config"
require "fileutils"
require "tmpdir"
require "yaml"

class KamalDockerConfigTest < ActiveSupport::TestCase
  test "isolate points Docker at a project-local config directory" do
    Dir.mktmpdir do |root|
      env = {}

      dir = KamalDockerConfig.isolate!(root: root, env: env)

      assert_equal File.join(root, ".kamal", "docker"), dir
      assert_equal dir, env["DOCKER_CONFIG"]
      assert File.directory?(dir)
    end
  end

  test "isolate does not overwrite an existing DOCKER_CONFIG" do
    Dir.mktmpdir do |root|
      env = { "DOCKER_CONFIG" => "/already/set" }

      KamalDockerConfig.isolate!(root: root, env: env)

      assert_equal "/already/set", env["DOCKER_CONFIG"]
    end
  end

  test "login uses the deploy registry user against the isolated docker config" do
    Dir.mktmpdir do |root|
      write_deploy_yml(root, server: "ghcr.io", username: "laurentqro")
      calls = []
      env = { "KAMAL_REGISTRY_PASSWORD" => "project-token" }

      KamalDockerConfig.login!(
        root: root,
        env: env,
        runner: ->(**kwargs) { calls << kwargs }
      )

      assert_equal [
        {
          server: "ghcr.io",
          username: "laurentqro",
          password: "project-token",
          docker_config: File.join(root, ".kamal", "docker")
        }
      ], calls
    end
  end

  test "login fails when the registry password is missing" do
    Dir.mktmpdir do |root|
      write_deploy_yml(root, server: "ghcr.io", username: "laurentqro")

      error = assert_raises(KeyError) do
        KamalDockerConfig.login!(root: root, env: {}, runner: ->(**) {})
      end

      assert_match(/KAMAL_REGISTRY_PASSWORD/, error.message)
    end
  end

  test "this app's deploy config logs into ghcr.io as laurentqro" do
    source = File.read(Rails.root.join("config/deploy.yml")).gsub(/<%.*?%>/m, "")
    config = YAML.safe_load(source)

    assert_equal "ghcr.io", config.fetch("registry").fetch("server")
    assert_equal "laurentqro", config.fetch("registry").fetch("username")
  end

  private
    def write_deploy_yml(root, server:, username:)
      FileUtils.mkdir_p(File.join(root, "config"))
      File.write(File.join(root, "config", "deploy.yml"), <<~YAML)
        registry:
          server: #{server}
          username: #{username}
          password:
            - KAMAL_REGISTRY_PASSWORD
      YAML
    end
end
