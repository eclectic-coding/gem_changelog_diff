# frozen_string_literal: true

module GemChangelogDiff
  class Configuration
    attr_accessor :github_token, :cache_enabled, :cache_ttl

    def initialize
      @cache_enabled = true
      @cache_ttl = 86_400
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
