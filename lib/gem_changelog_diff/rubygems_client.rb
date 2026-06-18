# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  class RubygemsClient
    RUBYGEMS_API = "https://rubygems.org/api/v1/gems/%<name>s.json"
    GITHUB_REPO_REGEX = %r{github\.com/([^/]+)/([^/]+)}

    def repo_url(gem_name)
      data = fetch_gem_data(gem_name)
      return nil unless data

      extract_github_repo(data)
    end

    def latest_version(gem_name)
      data = fetch_gem_data(gem_name)
      data&.dig("version")
    end

    private

    def fetch_gem_data(gem_name)
      uri = URI(format(RUBYGEMS_API, name: gem_name))
      response = Net::HTTP.get_response(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Net::OpenTimeout, Net::ReadTimeout => e
      raise NetworkError, "RubyGems API request failed: #{e.message}"
    end

    def extract_github_repo(data)
      %w[source_code_uri homepage_uri bug_tracker_uri].each do |field|
        url = data[field]
        next if url.nil? || url.empty?

        match = url.match(GITHUB_REPO_REGEX)
        next unless match

        owner = match[1]
        repo = match[2].sub(/\.git\z/, "").sub(%r{/.*}, "")
        return "#{owner}/#{repo}"
      end

      nil
    end
  end
end
