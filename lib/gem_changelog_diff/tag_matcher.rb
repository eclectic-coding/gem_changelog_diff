# frozen_string_literal: true

module GemChangelogDiff
  # Extracts version strings from various Git tag formats.
  class TagMatcher
    STANDARD_PATTERN = /\A(?:release-)?v?(\d+\..+)\z/

    def initialize(gem_name: nil)
      @gem_name = gem_name
    end

    # Parses a version string from a tag name.
    # @param tag [String, nil] the Git tag name
    # @return [String, nil] extracted version, or nil if unparseable
    def extract_version(tag)
      return nil if tag.nil? || tag.strip.empty?

      version = try_gem_prefixed(tag) || try_standard_pattern(tag)
      return nil unless version

      validate_version(version)
    end

    private

    def try_gem_prefixed(tag)
      return nil unless @gem_name

      prefix = "#{@gem_name}-"
      return nil unless tag.start_with?(prefix)

      raw = tag.delete_prefix(prefix)
      raw.start_with?("v") ? raw[1..] : raw
    end

    def try_standard_pattern(tag)
      match = tag.match(STANDARD_PATTERN)
      match ? match[1] : nil
    end

    def validate_version(version_str)
      Gem::Version.new(version_str)
      version_str
    rescue ArgumentError
      nil
    end
  end
end
