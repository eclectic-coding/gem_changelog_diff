# frozen_string_literal: true

require "net/http"
require "uri"

module GemChangelogDiff
  # Resolves a gem's RubyGems metadata to a GitHub owner/repo slug.
  class UriResolver
    GITHUB_REGEX = %r{github\.com/([^/]+)/([^/]+)}
    NON_GITHUB_HOSTS = {
      "gitlab.com" => "GitLab",
      "codeberg.org" => "Codeberg",
      "bitbucket.org" => "Bitbucket",
      "sr.ht" => "SourceHut"
    }.freeze
    URI_FIELDS = %w[source_code_uri homepage_uri bug_tracker_uri].freeze
    MAX_REDIRECTS = 3

    # Extracts a GitHub slug from gem metadata, following redirects.
    # @param gem_data [Hash<String, Object>] RubyGems API response data
    # @return [String, nil] "owner/repo" slug, or nil if not on GitHub
    # @raise [RepoNotFoundError] if hosted on a non-GitHub platform
    def resolve(gem_data)
      uris = extract_uris(gem_data)
      return nil if uris.empty?

      non_github = detect_non_github(uris)
      raise RepoNotFoundError, "hosted on #{non_github} (not supported)" if non_github

      slug = extract_github_slug(uris)
      return nil unless slug

      follow_redirects(slug)
    end

    private

    def extract_uris(data)
      URI_FIELDS.filter_map do |field|
        value = data[field]
        value unless value.nil? || value.to_s.strip.empty?
      end
    end

    def detect_non_github(uris)
      uris.each do |url|
        host = URI.parse(url).host&.downcase
        NON_GITHUB_HOSTS.each do |domain, name|
          return name if host&.end_with?(domain)
        end
      rescue URI::InvalidURIError
        next
      end
      nil
    end

    def extract_github_slug(uris)
      uris.each do |url|
        match = url.match(GITHUB_REGEX)
        next unless match

        owner = match[1]
        repo = match[2].sub(/\.git\z/, "").sub(%r{/.*}, "")
        return "#{owner}/#{repo}"
      end
      nil
    end

    def follow_redirects(slug, remaining = MAX_REDIRECTS)
      return slug if remaining <= 0

      response = execute_head_request(URI("https://api.github.com/repos/#{slug}"))
      return slug unless response.is_a?(Net::HTTPRedirection)

      new_slug = extract_slug_from_location(response["Location"])
      new_slug ? follow_redirects(new_slug, remaining - 1) : slug
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Errno::ETIMEDOUT, Errno::ECONNRESET,
           Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError
      slug
    end

    def extract_slug_from_location(location)
      location&.match(%r{repos/([^/]+/[^/]+)})&.then { |m| m[1] }
    end

    def execute_head_request(uri)
      request = Net::HTTP::Head.new(uri)
      request_headers.each { |k, v| request[k] = v }
      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        http.request(request)
      end
    end

    def request_headers
      headers = {
        "Accept" => "application/vnd.github.v3+json",
        "User-Agent" => "gem_changelog_diff/#{VERSION}"
      }
      token = GemChangelogDiff.configuration.github_token
      headers["Authorization"] = "token #{token}" if token
      headers
    end
  end
end
