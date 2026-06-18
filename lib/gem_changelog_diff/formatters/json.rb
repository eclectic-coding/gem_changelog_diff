# frozen_string_literal: true

require "json"

module GemChangelogDiff
  module Formatters
    # JSON formatter for machine-readable output.
    class Json < Base
      def format(gem_reports)
        counts = summary_counts(gem_reports)

        data = {
          gems: gem_reports.map { |report| format_gem(report) },
          summary: counts
        }

        JSON.pretty_generate(data)
      end

      private

      def format_gem(report)
        result = {
          gem: report[:gem].to_h,
          releases: report[:releases].map { |r| stringify_release(r) }
        }
        result[:error] = report[:error] if report[:error]
        result
      end

      def stringify_release(release)
        {
          tag_name: release[:tag_name],
          name: release[:name],
          published_at: release[:published_at],
          body: release[:body]
        }
      end
    end
  end
end
