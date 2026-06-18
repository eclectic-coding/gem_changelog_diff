# frozen_string_literal: true

require "bundler"

module GemChangelogDiff
  # Detects outdated gems by comparing Gemfile.lock specs to RubyGems.
  class LockfileParser
    def initialize(rubygems_client: RubygemsClient.new)
      @rubygems_client = rubygems_client
    end

    # Parses the lockfile and returns gems with newer versions available.
    # @param lockfile_path [String] path to Gemfile.lock
    # @return [Array<OutdatedGem>]
    # @raise [Error] if the lockfile is not found
    def detect(lockfile_path: "Gemfile.lock")
      content = File.read(lockfile_path)
      parser = Bundler::LockfileParser.new(content)
      find_outdated(parser.specs)
    rescue Errno::ENOENT
      raise Error, "Lockfile not found: #{lockfile_path}"
    end

    private

    def find_outdated(specs)
      specs.filter_map { |spec| check_gem(spec) }
    end

    def check_gem(spec)
      latest = @rubygems_client.latest_version(spec.name)
      return nil unless latest

      latest_version = Gem::Version.new(latest)
      return nil unless latest_version > spec.version

      OutdatedGem.new(
        name: spec.name,
        current_version: spec.version.to_s,
        newest_version: latest
      )
    end
  end
end
