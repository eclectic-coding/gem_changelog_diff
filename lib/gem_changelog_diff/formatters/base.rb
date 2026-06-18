# frozen_string_literal: true

module GemChangelogDiff
  module Formatters
    def self.build(format:, color: false)
      case format
      when "text" then Text.new(color: color)
      when "json" then Json.new
      when "markdown" then Markdown.new
      else raise ArgumentError, "Unknown format: #{format}. Valid formats: text, json, markdown"
      end
    end

    class Base
      def initialize(color: false)
        @color = color
      end

      def format(_gem_reports)
        raise NotImplementedError, "#{self.class}#format must be implemented"
      end

      private

      def summary_counts(gem_reports)
        {
          total: gem_reports.size,
          with_changelogs: gem_reports.count { |r| !r[:releases].empty? },
          skipped: gem_reports.count { |r| r[:error] }
        }
      end
    end
  end
end
