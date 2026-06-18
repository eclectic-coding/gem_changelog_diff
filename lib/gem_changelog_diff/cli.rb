# frozen_string_literal: true

require "thor"

module GemChangelogDiff
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    default_task :check

    class_option :token, type: :string, desc: "GitHub personal access token"
    class_option :verbose, type: :boolean, default: false, desc: "Show detailed output"
    class_option :quiet, type: :boolean, default: false, desc: "Suppress warnings"
    class_option :no_color, type: :boolean, default: false, desc: "Disable colored output"

    desc "check", "Show changelog diffs for outdated gems"
    def check
      configure_token
      gems = Detector.new.detect

      if gems.empty?
        say "All gems are up to date!"
        return
      end

      reports = build_reports(gems)
      formatter = Formatter.new(color: color_enabled?)
      say formatter.format(reports)
    end

    desc "version", "Print version"
    def version
      say "gem_changelog_diff #{VERSION}"
    end
    map "--version" => :version
    map "-v" => :version

    private

    def configure_token
      token = options[:token] || ENV.fetch("GITHUB_TOKEN", nil)
      GemChangelogDiff.configuration.github_token = token if token
    end

    def build_reports(gems)
      rubygems_client = RubygemsClient.new
      source_resolver = SourceResolver.new

      gems.map { |gem| build_gem_report(gem, rubygems_client, source_resolver) }
    end

    def build_gem_report(gem, rubygems_client, source_resolver)
      log "Checking #{gem.name}..."
      repo = rubygems_client.repo_url(gem.name)
      return { gem: gem, releases: [], error: "  Could not find GitHub repository." } if repo.nil?

      log "  Found repo: #{repo}"
      releases = source_resolver.resolve(repo, gem.current_version, gem.newest_version)
      { gem: gem, releases: releases }
    rescue GemChangelogDiff::Error => e
      log_warning "  Skipping #{gem.name}: #{e.message}"
      { gem: gem, releases: [], error: "  #{e.message}" }
    end

    def color_enabled?
      !options[:no_color]
    end

    def log(message)
      warn message if options[:verbose]
    end

    def log_warning(message)
      warn message unless options[:quiet]
    end
  end
end
