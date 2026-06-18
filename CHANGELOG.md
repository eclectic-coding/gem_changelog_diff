# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Disk cache at `~/.cache/gem_changelog_diff/` with configurable TTL (default 24h)
- ETag conditional requests to avoid consuming rate limit on revalidation
- `cache clear` subcommand
- `--no-cache` and `--cache-ttl` flags
- Concurrent fetching via thread pool (default 4, configurable via `--concurrency`)
- Progress indicator via `tty-spinner` when running in a terminal

## [0.4.0] - 2026-06-18

### Added

- `Gemfile.lock` parsing via `Bundler::LockfileParser` with RubyGems API version lookup
- Automatic fallback to lockfile parsing when `bundle outdated` is unavailable
- `--strategy` flag: `auto` (default), `outdated`, or `lockfile`
- `--lockfile` flag for custom lockfile path
- Positional arguments to inspect specific gems: `gem_changelog_diff check rails sidekiq`
- `--group` flag to filter by Bundler group
- `--ignore` flag to exclude specific gems

## [0.3.0] - 2026-06-18

### Added

- CHANGELOG.md fallback: fetches and parses changelog files when GitHub Releases are unavailable
- Tries common filename variants: `CHANGELOG.md`, `CHANGES.md`, `History.md`, `NEWS.md`
- `SourceResolver` orchestrates releases-first, changelog-fallback strategy
- Colorized terminal output via `tty-color`; respects `$NO_COLOR` and `--no-color` flag
- Summary line: "X gems outdated, Y with changelogs found, Z skipped"

## [0.2.0] - 2026-06-17

### Added

- GitHub personal access token support via `--token` flag or `GITHUB_TOKEN` env var
- `Configuration` singleton for managing runtime settings
- Custom error hierarchy: `RepoNotFoundError`, `GitHubAPIError`, `RateLimitError`, `NetworkError`
- Graceful degradation: failed gems are skipped with a warning instead of aborting
- Rate limit awareness: warns when GitHub API requests remaining drops below 10
- `--verbose` flag for detailed status output
- `--quiet` flag to suppress warnings

## [0.1.0] - 2026-06-17

### Added

- CLI entry point via Thor (`exe/gem_changelog_diff`) with `check` default command and `version` command
- Outdated gem detection by parsing `bundle outdated --parseable`
- `OutdatedGem` data object for representing outdated gem info
- RubyGems API client to look up each gem's GitHub repository
- GitHub API client to fetch releases between locked and latest versions
- Plain text formatter for changelog output
- Full end-to-end pipeline: detect → lookup → fetch → format

[Unreleased]: https://github.com/eclectic-coding/gem_changelog_diff/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/eclectic-coding/gem_changelog_diff/releases/tag/v0.4.0
[0.3.0]: https://github.com/eclectic-coding/gem_changelog_diff/releases/tag/v0.3.0
[0.2.0]: https://github.com/eclectic-coding/gem_changelog_diff/releases/tag/v0.2.0
[0.1.0]: https://github.com/eclectic-coding/gem_changelog_diff/releases/tag/v0.1.0
