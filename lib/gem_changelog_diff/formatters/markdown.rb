# frozen_string_literal: true

module GemChangelogDiff
  module Formatters
    # Markdown formatter for PR descriptions and documentation.
    class Markdown < Base
      def format(gem_reports)
        sections = gem_reports.map { |report| format_gem(report) }
        sections.push(summary(gem_reports))
        sections.join("\n")
      end

      private

      def format_gem(report)
        gem = report[:gem]
        header = "## #{gem.name} (#{gem.current_version} → #{gem.newest_version})"

        body = if report[:releases].empty?
                 report[:error] || "No changelog entries found."
               else
                 report[:releases].map { |r| format_release(r) }.join("\n")
               end

        "#{header}\n\n#{body}\n"
      end

      def format_release(release)
        title = "### #{release[:tag_name]}"
        title += " (#{release[:published_at][0..9]})" if release[:published_at]

        body = release[:body]&.strip.to_s
        body = "*(no release notes)*" if body.empty?
        "#{title}\n\n#{body}\n"
      end

      def summary(gem_reports)
        counts = summary_counts(gem_reports)
        "_#{counts[:total]} gems outdated, #{counts[:with_changelogs]} with changelogs found, " \
          "#{counts[:skipped]} skipped_\n"
      end
    end
  end
end
