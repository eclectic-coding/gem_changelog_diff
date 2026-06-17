# frozen_string_literal: true

require "net/http"
require "json"

module GemChangelogDiff
  class ChangelogParser
    CONTENTS_URL = "https://api.github.com/repos/%<repo>s/contents/%<path>s"
    FILENAMES = %w[CHANGELOG.md CHANGES.md History.md NEWS.md].freeze
    VERSION_HEADING = /^##\s+\[?v?(\d+[^\]\s]+)/

    def entries_between(repo, current_version, newest_version)
      content = fetch_changelog(repo)
      return [] unless content

      parse_entries(content, current_version, newest_version)
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           Net::OpenTimeout, Net::ReadTimeout => e
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
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github.v3+json"
      request["User-Agent"] = "gem_changelog_diff/#{VERSION}"

      token = GemChangelogDiff.configuration.github_token
      request["Authorization"] = "token #{token}" if token

      Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    end

    def parse_entries(content, current_version, newest_version)
      current = Gem::Version.new(current_version)
      newest = Gem::Version.new(newest_version)
      sections = split_sections(content)

      matched = sections.filter_map { |v, body| build_entry(v, body, current, newest) }
      matched.sort_by { |e| Gem::Version.new(e[:tag_name]) }.reverse
    end

    def build_entry(version_str, body, current, newest)
      gem_version = Gem::Version.new(version_str)
      return unless gem_version > current && gem_version <= newest

      { tag_name: version_str, name: version_str, published_at: nil, body: body.strip }
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
