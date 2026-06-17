# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  class GithubClient
    RELEASES_URL = "https://api.github.com/repos/%<repo>s/releases"
    TAG_VERSION_REGEX = /\Av?(\d+\..+)\z/
    RATE_LIMIT_WARNING_THRESHOLD = 10

    def releases_between(repo, current_version, newest_version)
      releases = fetch_releases(repo)
      filter_releases(releases, current_version, newest_version)
    end

    private

    def fetch_releases(repo)
      uri = URI(format(RELEASES_URL, repo: repo))
      uri.query = URI.encode_www_form(per_page: 30)

      response = execute_request(uri)
      check_rate_limit(response)
      handle_response(response)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Net::OpenTimeout, Net::ReadTimeout => e
      raise NetworkError, "GitHub API request failed: #{e.message}"
    end

    def execute_request(uri)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github.v3+json"
      request["User-Agent"] = "gem_changelog_diff/#{VERSION}"
      apply_auth(request)

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    end

    def apply_auth(request)
      token = GemChangelogDiff.configuration.github_token
      request["Authorization"] = "token #{token}" if token
    end

    def handle_response(response)
      return [] if response.code == "404"

      if response.code == "403" && response["X-RateLimit-Remaining"] == "0"
        raise RateLimitError, "GitHub API rate limit exceeded. Use --token to authenticate."
      end

      raise GitHubAPIError, "GitHub API error (HTTP #{response.code})" unless response.is_a?(Net::HTTPSuccess)

      JSON.parse(response.body)
    end

    def check_rate_limit(response)
      remaining = response["X-RateLimit-Remaining"]&.to_i
      return if remaining.nil? || remaining >= RATE_LIMIT_WARNING_THRESHOLD

      warn "Warning: GitHub API rate limit low (#{remaining} requests remaining). Use --token to authenticate."
    end

    def filter_releases(releases, current_version, newest_version)
      current = Gem::Version.new(current_version)
      newest = Gem::Version.new(newest_version)

      matched = releases.filter_map { |r| build_release(r, current, newest) }
      sort_releases(matched)
    end

    def build_release(release, current, newest)
      version = extract_version(release["tag_name"])
      return unless version

      gem_version = Gem::Version.new(version)
      return unless gem_version > current && gem_version <= newest

      { tag_name: release["tag_name"], name: release["name"],
        published_at: release["published_at"], body: release["body"] }
    end

    def sort_releases(releases)
      releases.sort_by { |r| Gem::Version.new(extract_version(r[:tag_name])) }.reverse
    end

    def extract_version(tag)
      match = tag&.match(TAG_VERSION_REGEX)
      match ? match[1] : nil
    end
  end
end
