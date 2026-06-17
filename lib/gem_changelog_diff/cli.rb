# frozen_string_literal: true

require "thor"

module GemChangelogDiff
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    default_task :check

    class_option :token, type: :string, desc: "GitHub personal access token"

    desc "check", "Show changelog diffs for outdated gems"
    def check
      configure_token
      gems = Detector.new.detect

      if gems.empty?
        say "All gems are up to date!"
        return
      end

      reports = build_reports(gems)
      say Formatter.new.format(reports)
    end

    desc "version", "Print version"
    def version
      say "gem_changelog_diff #{VERSION}"
    end
    map "--version" => :version
    map "-v" => :version

    private

    def build_reports(gems)
      rubygems_client = RubygemsClient.new
      github_client = GithubClient.new

      gems.map { |gem| build_gem_report(gem, rubygems_client, github_client) }
    end

    def configure_token
      token = options[:token] || ENV.fetch("GITHUB_TOKEN", nil)
      GemChangelogDiff.configuration.github_token = token if token
    end

    def build_gem_report(gem, rubygems_client, github_client)
      repo = rubygems_client.repo_url(gem.name)
      return { gem: gem, releases: [], error: "  Could not find GitHub repository." } if repo.nil?

      releases = github_client.releases_between(repo, gem.current_version, gem.newest_version)
      { gem: gem, releases: releases }
    end
  end
end
