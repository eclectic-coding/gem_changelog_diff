# frozen_string_literal: true

require "thor"

module GemChangelogDiff
  class CLI < Thor
    default_task :check

    desc "check", "Show changelog diffs for outdated gems"
    def check
      detector = Detector.new
      gems = detector.detect

      if gems.empty?
        say "All gems are up to date!"
        return
      end

      gems.each do |gem|
        say "#{gem.name} (#{gem.current_version} → #{gem.newest_version})"
      end
    end

    desc "version", "Print version"
    def version
      say "gem_changelog_diff #{VERSION}"
    end
    map "--version" => :version
    map "-v" => :version
  end
end
