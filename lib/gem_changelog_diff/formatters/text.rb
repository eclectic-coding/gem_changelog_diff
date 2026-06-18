# frozen_string_literal: true

require "tty-color"

module GemChangelogDiff
  module Formatters
    class Text < Base
      BOLD = "\e[1m"
      CYAN = "\e[36m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      RED = "\e[31m"
      RESET = "\e[0m"

      def initialize(color: default_color?)
        super
      end

      def format(gem_reports)
        output = gem_reports.map { |report| format_gem(report) }.join("\n")
        output + summary(gem_reports)
      end

      private

      def default_color?
        TTY::Color.color? && ENV.fetch("NO_COLOR", nil).nil?
      end

      def format_gem(report)
        gem = report[:gem]
        header = colorize("== #{gem.name} (#{gem.current_version} → #{gem.newest_version}) ==", BOLD, CYAN)

        body = if report[:releases].empty?
                 colorize(report[:error] || "  No changelog entries found.", RED)
               else
                 report[:releases].map { |r| format_release(r) }.join("\n")
               end

        "#{header}\n#{body}\n"
      end

      def format_release(release)
        title = "--- #{release[:tag_name]}"
        title += " (#{release[:published_at][0..9]})" if release[:published_at]
        title += " ---"
        title = colorize(title, YELLOW)

        body = release[:body]&.strip.to_s
        body = "(no release notes)" if body.empty?
        "#{title}\n#{body}\n"
      end

      def summary(gem_reports)
        counts = summary_counts(gem_reports)
        line = "\n#{counts[:total]} gems outdated, #{counts[:with_changelogs]} with changelogs found, " \
               "#{counts[:skipped]} skipped"
        colorize(line, BOLD, GREEN)
      end

      def colorize(text, *codes)
        return text unless @color

        "#{codes.join}#{text}#{RESET}"
      end
    end
  end
end
