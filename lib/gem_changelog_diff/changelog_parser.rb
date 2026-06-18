# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  # Parses CHANGELOG.md files from GitHub repos as a fallback source.
  class ChangelogParser
    CONTENTS_URL = "https://api.github.com/repos/%<repo>s/contents/%<path>s"
    FILENAMES = %w[CHANGELOG.md CHANGES.md History.md NEWS.md].freeze
    VERSION_HEADING = /^##\s+\[?v?(\d+[^\]\s]+)/

    def initialize(cache: nil)
      @cache = cache
    end

    # Parses changelog entries between two versions from a repo's changelog file.
    # @param repo [String] GitHub "owner/repo" slug
    # @param current_version [String] currently locked version (exclusive)
    # @param newest_version [String] target version (inclusive)
    # @return [Array<Hash>] release hashes with :tag_name, :name, :published_at, :body
    # @raise [NetworkError] on HTTP connection failures
    def entries_between(repo, current_version, newest_version)
      content = fetch_changelog(repo)
      return [] unless content

      parse_entries(content, current_version, newest_version)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Errno::ETIMEDOUT, Errno::ECONNRESET,
           Net::OpenTimeout, Net::ReadTimeout,
           OpenSSL::SSL::SSLError => e
      raise NetworkError, "GitHub API request failed: #{e.message}"
    end

    private

    def fetch_changelog(repo)
      FILENAMES.each do |filename|
        content = fetch_file(repo, filename)
        return content if content
      end

      nil
    end

    def fetch_file(repo, path)
      uri = URI(format(CONTENTS_URL, repo: repo, path: path))
      response = execute_request(uri)
      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data["content"].unpack1("m")
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

    def parse_entries(content, current_version, newest_version)
      current = safe_gem_version(current_version)
      newest = safe_gem_version(newest_version)
      return [] unless current && newest

      sections = split_sections(content)
      matched = sections.filter_map { |v, body| build_entry(v, body, current, newest) }
      matched.sort_by { |e| safe_gem_version(e[:tag_name]) || Gem::Version.new("0") }.reverse
    end

    def build_entry(version_str, body, current, newest)
      gem_version = safe_gem_version(version_str)
      return unless gem_version && gem_version > current && gem_version <= newest

      { tag_name: version_str, name: version_str, published_at: nil, body: body.strip }
    end

    def safe_gem_version(version_str)
      Gem::Version.new(version_str)
    rescue ArgumentError
      nil
    end

    def split_sections(content)
      sections = []
      current_version = nil
      current_body = []

      content.each_line do |line|
        current_version, current_body = process_line(line, sections, current_version, current_body)
      end

      flush_section(sections, current_version, current_body)
      sections
    end

    def process_line(line, sections, current_version, current_body)
      match = line.match(VERSION_HEADING)
      if match
        flush_section(sections, current_version, current_body)
        [clean_version(match[1]), []]
      else
        current_body << line if current_version
        [current_version, current_body]
      end
    end

    def flush_section(sections, version, body)
      sections << [version, body.join] if version
    end

    def clean_version(raw)
      raw.sub(/\]\s*-?\s*\d{4}-\d{2}-\d{2}.*/, "").strip
    end
  end
end
