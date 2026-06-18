# frozen_string_literal: true

require "yaml"

module GemChangelogDiff
  # Loads and merges YAML config from user and project locations.
  class ConfigLoader
    USER_CONFIG_DIR = File.join(Dir.home, ".config", "gem_changelog_diff")
    USER_CONFIG_PATH = File.join(USER_CONFIG_DIR, "config.yml")
    PROJECT_CONFIG_NAME = ".gem_changelog_diff.yml"

    def initialize(project_dir: Dir.pwd)
      @project_dir = project_dir
    end

    # Loads config from user and project files, with project taking priority.
    # @return [Hash<Symbol, Object>]
    def load
      user_config = load_file(USER_CONFIG_PATH)
      project_config = load_file(project_config_path)
      user_config.merge(project_config)
    end

    private

    def project_config_path
      File.join(@project_dir, PROJECT_CONFIG_NAME)
    end

    def load_file(path)
      return {} unless File.exist?(path)

      result = YAML.safe_load_file(path, permitted_classes: [], symbolize_names: true)
      result.is_a?(Hash) ? result : {}
    rescue Psych::SyntaxError
      {}
    end
  end
end
