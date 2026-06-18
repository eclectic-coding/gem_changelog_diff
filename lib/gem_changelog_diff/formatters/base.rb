# frozen_string_literal: true

module GemChangelogDiff
  # Output formatters for rendering gem reports.
  module Formatters
    # Builds a formatter instance for the given format name.
    # @param format [String] "text", "json", or "markdown"
    # @param color [Boolean] whether to enable ANSI colors
    # @return [Text, Json, Markdown]
    # @raise [ArgumentError] for unknown formats
    def self.build(format:, color: false)
      case format
      when "text" then Text.new(color: color)
      when "json" then Json.new
      when "markdown" then Markdown.new
      else raise ArgumentError, "Unknown format: #{format}. Valid formats: text, json, markdown"
      end
    end

    # Abstract base class for output formatters.
    class Base
      def initialize(color: false)
        @color = color
      end

      # Formats gem reports into a string.
      # @param _gem_reports [Array<Hash>] list of gem report hashes
      # @return [String]
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
