# frozen_string_literal: true

module GemChangelogDiff
  class Configuration
    attr_accessor :github_token, :cache_enabled, :cache_ttl,
                  :default_format, :concurrency, :ignore_gems, :no_color

    VALID_KEYS = %i[github_token cache_enabled cache_ttl default_format concurrency ignore_gems no_color].freeze

    def initialize
      @cache_enabled = true
      @cache_ttl = 86_400
      @default_format = "text"
      @concurrency = 4
      @ignore_gems = []
      @no_color = false
    end

    def apply(hash)
      hash.each do |key, value|
        public_send(:"#{key}=", value) if VALID_KEYS.include?(key) && !value.nil?
      end
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
