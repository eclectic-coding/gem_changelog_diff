# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  # Queries the RubyGems.org API for gem metadata and source repository URLs.
  class RubygemsClient
    RUBYGEMS_API = "https://rubygems.org/api/v1/gems/%<name>s.json"

    def initialize(cache: nil, uri_resolver: UriResolver.new)
      @cache = cache
      @uri_resolver = uri_resolver
    end

    # Looks up the GitHub repository slug for a gem.
    # @param gem_name [String]
    # @return [String, nil] "owner/repo" slug, or nil if not found
    def repo_url(gem_name)
      data = fetch_gem_data(gem_name)
      return nil unless data

      @uri_resolver.resolve(data)
    end

    # Returns the latest version string for a gem from RubyGems.
    # @param gem_name [String]
    # @return [String, nil]
    def latest_version(gem_name)
      data = fetch_gem_data(gem_name)
      data&.dig("version")
    end

    private

    def fetch_gem_data(gem_name)
      uri = URI(format(RUBYGEMS_API, name: gem_name))
      response = @cache ? @cache.get(uri) : fetch_from_api(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Errno::ETIMEDOUT, Errno::ECONNRESET,
           Net::OpenTimeout, Net::ReadTimeout,
           OpenSSL::SSL::SSLError, JSON::ParserError => e
      raise NetworkError, "RubyGems API request failed: #{e.message}"
    end

    def fetch_from_api(uri)
      timeout = GemChangelogDiff.configuration.request_timeout
      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
        http.request(Net::HTTP::Get.new(uri))
      end
    end
  end
end
