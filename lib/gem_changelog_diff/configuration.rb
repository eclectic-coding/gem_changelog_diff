# frozen_string_literal: true

module GemChangelogDiff
  class Configuration
    attr_accessor :github_token
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
