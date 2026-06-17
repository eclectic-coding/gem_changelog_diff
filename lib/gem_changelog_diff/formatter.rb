# frozen_string_literal: true

module GemChangelogDiff
  class Formatter
    def format(gem_reports)
      gem_reports.map { |report| format_gem(report) }.join("\n")
    end

    private

    def format_gem(report)
      header = "== #{report[:gem].name} (#{report[:gem].current_version} → #{report[:gem].newest_version}) =="

      body = if report[:releases].empty?
               report[:error] || "  No GitHub releases found."
             else
               report[:releases].map { |r| format_release(r) }.join("\n")
             end

      "#{header}\n#{body}\n"
    end

    def format_release(release)
      title = "--- #{release[:tag_name]}"
      title += " (#{release[:published_at][0..9]})" if release[:published_at]
      title += " ---"
      body = release[:body]&.strip.to_s
      body = "(no release notes)" if body.empty?
      "#{title}\n#{body}\n"
    end
  end
end
