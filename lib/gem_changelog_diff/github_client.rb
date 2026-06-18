# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  class GithubClient
    RELEASES_URL = "https://api.github.com/repos/%<repo>s/releases"
    RATE_LIMIT_WARNING_THRESHOLD = 10
    MAX_PAGES = 10

    def initialize(cache: nil)
      @cache = cache
    end

    def releases_between(repo, current_version, newest_version)
      gem_name = repo.split("/").last
      @active_matcher = TagMatcher.new(gem_name: gem_name)
      releases = fetch_releases(repo, current_version)
      filter_releases(releases, current_version, newest_version)
    end

    private

    def fetch_releases(repo, current_version = nil)
      current = current_version ? safe_gem_version(current_version) : nil
      paginate_releases(repo, current)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Errno::ETIMEDOUT, Errno::ECONNRESET,
           Net::OpenTimeout, Net::ReadTimeout,
           OpenSSL::SSL::SSLError => e
      raise NetworkError, "GitHub API request failed: #{e.message}"
    end

    def paginate_releases(repo, current)
      all_releases = []

      (1..MAX_PAGES).each do |page|
        response, page_releases = fetch_release_page(repo, page)
        break if page_releases.empty?

        all_releases.concat(page_releases)
        break if current && oldest_before_current?(page_releases, current)
        break unless next_page?(response)
      end

      all_releases
    end

    def fetch_release_page(repo, page)
      uri = build_releases_uri(repo, page)
      response = execute_request(uri)
      check_rate_limit(response)
      [response, handle_response(response)]
    end

    def build_releases_uri(repo, page)
      uri = URI(format(RELEASES_URL, repo: repo))
      uri.query = URI.encode_www_form(per_page: 100, page: page)
      uri
    end

    def next_page?(response)
      link = response["Link"]
      return false unless link

      link.include?('rel="next"')
    end

    def oldest_before_current?(releases, current)
      releases.any? do |r|
        version = @active_matcher.extract_version(r["tag_name"])
        next false unless version

        gem_version = safe_gem_version(version)
        gem_version && gem_version < current
      end
    end

    def execute_request(uri)
      headers = request_headers
      return @cache.get(uri, headers: headers) if @cache

      timeout = GemChangelogDiff.configuration.request_timeout
      request = Net::HTTP::Get.new(uri)
      headers.each { |k, v| request[k] = v }
      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: true, open_timeout: timeout, read_timeout: timeout) do |http|
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

    def handle_response(response)
      return [] if %w[301 404].include?(response.code)

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
      current = safe_gem_version(current_version)
      newest = safe_gem_version(newest_version)
      return [] unless current && newest

      matched = releases.filter_map { |r| build_release(r, current, newest) }
      sort_releases(matched)
    end

    def build_release(release, current, newest)
      version_str = @active_matcher.extract_version(release["tag_name"])
      return unless version_str

      gem_version = safe_gem_version(version_str)
      return unless gem_version && gem_version > current && gem_version <= newest

      { tag_name: release["tag_name"], name: release["name"],
        published_at: release["published_at"], body: release["body"] }
    end

    def sort_releases(releases)
      releases.sort_by do |r|
        safe_gem_version(@active_matcher.extract_version(r[:tag_name])) || Gem::Version.new("0")
      end.reverse
    end

    def safe_gem_version(version_str)
      Gem::Version.new(version_str)
    rescue ArgumentError
      nil
    end
  end
end
