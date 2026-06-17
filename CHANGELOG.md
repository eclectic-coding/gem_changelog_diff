# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- GitHub personal access token support via `--token` flag or `GITHUB_TOKEN` env var
- `Configuration` singleton for managing runtime settings

## [0.1.0] - 2026-06-17

### Added

- CLI entry point via Thor (`exe/gem_changelog_diff`) with `check` default command and `version` command
- Outdated gem detection by parsing `bundle outdated --parseable`
- `OutdatedGem` data object for representing outdated gem info
- RubyGems API client to look up each gem's GitHub repository
- GitHub API client to fetch releases between locked and latest versions
- Plain text formatter for changelog output
- Full end-to-end pipeline: detect → lookup → fetch → format

[Unreleased]: https://github.com/eclectic-coding/gem_changelog_diff/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/eclectic-coding/gem_changelog_diff/releases/tag/v0.1.0
