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
    class_option :lockfile, type: :string, desc: "Path to Gemfile.lock"
    class_option :strategy, type: :string, default: "auto", desc: "Detection strategy (auto, outdated, lockfile)"
    class_option :group, type: :string, desc: "Filter by Bundler group"
    class_option :ignore, type: :array, desc: "Gems to skip"
    class_option :no_cache, type: :boolean, default: false, desc: "Disable caching"
    class_option :cache_ttl, type: :numeric, desc: "Cache TTL in seconds"
    class_option :concurrency, type: :numeric, default: 4, desc: "Number of concurrent fetches"

    desc "check [GEM...]", "Show changelog diffs for outdated gems"
    def check(*gem_names)
      configure_token
      gems = detect_gems
      gems = filter_gems(gems, gem_names)

      if gems.empty?
        say "All gems are up to date!"
        return
      end

      reports = with_spinner { build_reports(gems) }
      formatter = Formatter.new(color: color_enabled?)
      say formatter.format(reports)
    end

    desc "cache SUBCOMMAND", "Manage the cache"
    def cache(subcommand = nil)
      case subcommand
      when "clear"
        Cache.new.clear
        say "Cache cleared."
      else
        say "Usage: gem_changelog_diff cache clear"
      end
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

    def build_cache
      ttl = options[:cache_ttl] || GemChangelogDiff.configuration.cache_ttl
      enabled = !options[:no_cache] && GemChangelogDiff.configuration.cache_enabled
      Cache.new(ttl: ttl, enabled: enabled)
    end

    def detect_gems
      case options[:strategy]
      when "lockfile"
        detect_via_lockfile
      when "outdated"
        Detector.new(group: options[:group]).detect
      else
        detect_with_fallback
      end
    end

    def detect_with_fallback
      Detector.new(group: options[:group]).detect
    rescue Error
      log_warning "  bundle outdated failed, falling back to lockfile parsing..."
      detect_via_lockfile
    end

    def detect_via_lockfile
      lockfile_path = options[:lockfile] || "Gemfile.lock"
      LockfileParser.new.detect(lockfile_path: lockfile_path)
    end

    def filter_gems(gems, gem_names)
      gems = gems.select { |g| gem_names.include?(g.name) } if gem_names.any?
      gems = gems.reject { |g| ignore_list.include?(g.name) } if ignore_list.any?
      gems
    end

    def ignore_list
      @ignore_list ||= options[:ignore] || []
    end

    def build_reports(gems)
      cache = build_cache
      rubygems_client = RubygemsClient.new(cache: cache)
      source_resolver = SourceResolver.new(
        github_client: GithubClient.new(cache: cache),
        changelog_parser: ChangelogParser.new(cache: cache)
      )
      fetcher = ConcurrentFetcher.new(concurrency: options[:concurrency])

      fetcher.fetch_all(gems) { |gem| build_gem_report(gem, rubygems_client, source_resolver) }
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

    def with_spinner
      unless options[:quiet] || !$stderr.tty?
        require "tty-spinner"
        spinner = TTY::Spinner.new("[:spinner] Fetching changelogs...", format: :dots, output: $stderr)
        spinner.auto_spin
      end

      result = yield
      spinner&.stop("Done!")
      result
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
