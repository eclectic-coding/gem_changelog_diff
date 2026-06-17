# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- CLI entry point via Thor (`exe/gem_changelog_diff`) with `check` default command and `version` command
- Outdated gem detection by parsing `bundle outdated --parseable`
- `OutdatedGem` data object for representing outdated gem info
