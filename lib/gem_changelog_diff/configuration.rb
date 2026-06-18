# frozen_string_literal: true

module GemChangelogDiff
  # Holds runtime settings for the gem (token, cache, format, timeouts).
  class Configuration
    # @return [String, nil] GitHub personal access token
    # @return [Boolean] whether disk caching is enabled
    # @return [Integer] cache time-to-live in seconds
    # @return [String] default output format ("text", "json", "markdown")
    # @return [Integer] number of concurrent fetch threads
    # @return [Array<String>] gem names to skip
    # @return [Boolean] whether to disable colored output
    # @return [Integer] per-request HTTP timeout in seconds
    # @return [Integer] total operation timeout in seconds
    attr_accessor :github_token, :cache_enabled, :cache_ttl,
                  :default_format, :concurrency, :ignore_gems, :no_color,
                  :request_timeout, :total_timeout

    VALID_KEYS = %i[github_token cache_enabled cache_ttl default_format concurrency
                    ignore_gems no_color request_timeout total_timeout].freeze

    def initialize
      @cache_enabled = true
      @cache_ttl = 86_400
      @default_format = "text"
      @concurrency = 4
      @ignore_gems = []
      @no_color = false
      @request_timeout = 10
      @total_timeout = 120
    end

    # Applies a hash of settings, ignoring unknown keys and nil values.
    # @param hash [Hash<Symbol, Object>] configuration key-value pairs
    # @return [void]
    def apply(hash)
      hash.each do |key, value|
        public_send(:"#{key}=", value) if VALID_KEYS.include?(key) && !value.nil?
      end
    end
  end

  # Returns the global configuration instance.
  # @return [Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Yields the global configuration for modification.
  # @yieldparam config [Configuration]
  # @return [void]
  def self.configure
    yield(configuration)
  end

  # Resets the global configuration to defaults.
  # @return [Configuration]
  def self.reset_configuration!
    @configuration = Configuration.new
  end
end
