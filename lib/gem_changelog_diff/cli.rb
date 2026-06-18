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
    class_option :format, type: :string, default: "text", desc: "Output format (text, json, markdown)"
    class_option :output, type: :string, desc: "Write output to file instead of stdout"
    class_option :interactive, type: :boolean, default: false, aliases: "-i",
                               desc: "Interactively select gems to check"
    class_option :dry_run, type: :boolean, default: false, desc: "Show which gems would be checked"
    class_option :timeout, type: :numeric, desc: "Per-request timeout in seconds (default: 10)"

    desc "check [GEM...]", "Show changelog diffs for outdated gems"
    def check(*gem_names)
      setup_environment
      gems = filter_gems(detect_gems, gem_names)
      return say("All gems are up to date!") if gems.empty?

      gems = apply_interactive(gems)
      return say("No gems selected.") if gems.empty?
      return dry_run_output(gems) if options[:dry_run]

      exit exit_status(output_results(gems))
    end

    desc "show GEM FROM_VERSION TO_VERSION", "Show changelog between two versions of a gem"
    def show(gem_name, from_version, to_version)
      setup_environment
      gem = OutdatedGem.new(name: gem_name, current_version: from_version, newest_version: to_version)
      report = build_single_report(gem)
      formatter = Formatters.build(format: resolved_format, color: color_enabled?)
      write_output(formatter.format([report]))
      exit report[:error] ? ExitCode::ERROR : ExitCode::SUCCESS
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

    desc "init", "Generate a config file template"
    def init
      path = ConfigLoader::PROJECT_CONFIG_NAME
      if File.exist?(path)
        say "#{path} already exists."
        return
      end

      File.write(path, config_template)
      say "Created #{path}"
    end

    desc "version", "Print version"
    def version
      say "gem_changelog_diff #{VERSION}"
    end
    map "--version" => :version
    map "-v" => :version

    private

    def setup_environment
      load_config
      configure_token
      configure_timeout
    end

    def load_config
      config = ConfigLoader.new.load
      GemChangelogDiff.configuration.apply(config)
    end

    def configure_token
      token = options[:token] || ENV.fetch("GITHUB_TOKEN", nil)
      token ||= rails_credentials_token
      token ||= GemChangelogDiff.configuration.github_token
      GemChangelogDiff.configuration.github_token = token if token
    end

    def configure_timeout
      timeout = options[:timeout] || GemChangelogDiff.configuration.request_timeout
      GemChangelogDiff.configuration.request_timeout = timeout
    end

    def rails_credentials_token
      return unless defined?(Rails) && Rails.application.respond_to?(:credentials)

      Rails.application.credentials.dig(:gem_changelog_diff, :github_token)
    rescue StandardError
      nil
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
      @ignore_list ||= (options[:ignore] || []) | GemChangelogDiff.configuration.ignore_gems
    end

    def build_reports(gems)
      cache = build_cache
      rubygems_client = RubygemsClient.new(cache: cache)
      source_resolver = SourceResolver.new(
        github_client: GithubClient.new(cache: cache),
        changelog_parser: ChangelogParser.new(cache: cache)
      )
      fetcher = ConcurrentFetcher.new(concurrency: resolved_concurrency)

      fetcher.fetch_all(gems) { |gem| build_gem_report(gem, rubygems_client, source_resolver) }
    end

    def build_gem_report(gem, rubygems_client, source_resolver)
      log "Checking #{gem.name}..."
      fetch_gem_releases(gem, rubygems_client, source_resolver)
    rescue GemChangelogDiff::Error => e
      log_warning "  Skipping #{gem.name}: #{e.message}"
      gem_error(gem, e.message)
    rescue JSON::ParserError => e
      log_warning "  Skipping #{gem.name}: malformed API response"
      gem_error(gem, "Malformed API response: #{e.message}")
    end

    def fetch_gem_releases(gem, rubygems_client, source_resolver)
      repo = rubygems_client.repo_url(gem.name)
      return gem_error(gem, "Could not determine source repository.") unless repo

      log "  Found repo: #{repo}"
      releases = source_resolver.resolve(repo, gem.current_version, gem.newest_version)
      { gem: gem, releases: releases }
    end

    def gem_error(gem, message)
      { gem: gem, releases: [], error: "  #{message}" }
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

    def dry_run_output(gems)
      write_output(format_dry_run(gems))
    end

    def format_dry_run(gems)
      case resolved_format
      when "json"
        require "json"
        JSON.pretty_generate(gems.map(&:to_h))
      when "markdown"
        gems.map { |g| "- **#{g.name}** (#{g.current_version} → #{g.newest_version})" }.join("\n")
      else
        gems.map { |g| "#{g.name} (#{g.current_version} → #{g.newest_version})" }.join("\n")
      end
    end

    def output_results(gems)
      reports = with_spinner { build_reports(gems) }
      formatter = Formatters.build(format: resolved_format, color: color_enabled?)
      write_output(formatter.format(reports))
      reports
    end

    def apply_interactive(gems)
      return gems unless options[:interactive]

      Interactive.new(gems: gems).select
    end

    def exit_status(reports)
      error_count = reports.count { |r| r[:error] }
      return ExitCode::SUCCESS if error_count.zero?
      return ExitCode::ERROR if error_count == reports.size

      ExitCode::PARTIAL_FAILURE
    end

    def resolved_format
      options[:format] || GemChangelogDiff.configuration.default_format
    end

    def resolved_concurrency
      options[:concurrency] || GemChangelogDiff.configuration.concurrency
    end

    def build_single_report(gem)
      cache = build_cache
      rubygems_client = RubygemsClient.new(cache: cache)
      source_resolver = SourceResolver.new(
        github_client: GithubClient.new(cache: cache),
        changelog_parser: ChangelogParser.new(cache: cache)
      )
      build_gem_report(gem, rubygems_client, source_resolver)
    end

    def write_output(text)
      if options[:output]
        File.write(options[:output], "#{text}\n")
        say "Output written to #{options[:output]}" unless options[:quiet]
      else
        say text
      end
    end

    def color_enabled?
      !options[:no_color] && !GemChangelogDiff.configuration.no_color
    end

    def config_template
      <<~YAML
        # gem_changelog_diff configuration
        # See: https://github.com/eclectic-coding/gem_changelog_diff

        # GitHub personal access token (or use GITHUB_TOKEN env var)
        # github_token: ghp_xxx

        # Default output format: text, json, markdown
        # default_format: text

        # Cache TTL in seconds (default: 86400 = 24 hours)
        # cache_ttl: 86400

        # Number of concurrent fetches (default: 4)
        # concurrency: 4

        # Gems to always ignore
        # ignore_gems:
        #   - rake
        #   - bundler

        # Disable colored output
        # no_color: false

        # Per-request timeout in seconds (default: 10)
        # request_timeout: 10

        # Total timeout in seconds (default: 120)
        # total_timeout: 120
      YAML
    end

    def log(message)
      warn message if options[:verbose]
    end

    def log_warning(message)
      warn message unless options[:quiet]
    end
  end
end
