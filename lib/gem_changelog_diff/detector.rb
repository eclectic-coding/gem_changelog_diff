# frozen_string_literal: true

require "open3"

module GemChangelogDiff
  class Detector
    PARSEABLE_REGEX = /\A(\S+)\s+\(newest\s+([^,]+),\s+installed\s+([^,)]+)/

    def detect
      output = run_bundle_outdated
      parse(output)
    end

    private

    def run_bundle_outdated
      output, status = Open3.capture2("bundle", "outdated", "--parseable")
      raise Error, "bundle outdated failed (exit #{status.exitstatus})" unless [0, 1].include?(status.exitstatus)

      output
    end

    def parse(output)
      output.each_line.filter_map do |line|
        match = line.match(PARSEABLE_REGEX)
        next unless match

        OutdatedGem.new(
          name: match[1],
          current_version: match[3],
          newest_version: match[2]
        )
      end
    end
  end
end
