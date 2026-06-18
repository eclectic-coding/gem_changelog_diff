# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  class RubygemsClient
    RUBYGEMS_API = "https://rubygems.org/api/v1/gems/%<name>s.json"

    def initialize(cache: nil, uri_resolver: UriResolver.new)
      @cache = cache
      @uri_resolver = uri_resolver
    end

    def repo_url(gem_name)
      data = fetch_gem_data(gem_name)
      return nil unless data

      @uri_resolver.resolve(data)
    end

    def latest_version(gem_name)
      data = fetch_gem_data(gem_name)
      data&.dig("version")
    end

    private

    def fetch_gem_data(gem_name)
      uri = URI(format(RUBYGEMS_API, name: gem_name))
      response = @cache ? @cache.get(uri) : Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Net::OpenTimeout, Net::ReadTimeout, JSON::ParserError => e
      raise NetworkError, "RubyGems API request failed: #{e.message}"
    end
  end
end
