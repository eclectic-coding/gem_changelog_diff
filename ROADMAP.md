# Roadmap

Feature roadmap for gem_changelog_diff. Each section is auto-pruned by `bin/release` when that version ships.

## 0.7.0 -- Configuration File & Polish

Persistent preferences so users don't repeat flags every run.

- Config file: `.gem_changelog_diff.yml` (project root) and `~/.config/gem_changelog_diff/config.yml` (user); project overrides user
- Supported keys: `github_token`, `default_format`, `cache_ttl`, `concurrency`, `ignore_gems`, `no_color`
- `init` subcommand: generate a commented config template
- `version` subcommand
- `--dry-run` flag: show which gems would be checked without fetching
- Rails credentials support: read token from `Rails.application.credentials.dig(:gem_changelog_diff, :github_token)` when running inside a Rails app

**New files:** `config_loader.rb`

---

## 0.8.0 -- Robustness & Edge Cases

Handle the long tail of real-world gem repository patterns.

- Source URI resolution: detect and skip GitLab/Codeberg gracefully, follow redirects for renamed repos, handle monorepo subdirectory URIs
- Tag format normalization: `v1.2.3`, `1.2.3`, `gem_name-1.2.3`, `release-1.2.3`
- Proper version comparison via `Gem::Version` (handles pre-release: `1.0.0.rc1`, `1.0.0.beta2`)
- GitHub API pagination for gems with 100+ releases
- Per-request timeout (10s default), total timeout (120s default), configurable via `--timeout`

**New files:** `tag_matcher.rb`, `uri_resolver.rb`

---

## 0.9.0 -- Pre-1.0 Stabilization

Freeze the public API. Harden the test suite. Prepare documentation for stable release.

- Integration test suite with VCR-recorded HTTP fixtures against well-known gems
- RBS type signatures in `sig/gem_changelog_diff.rbs`
- Defined exit codes: 0 (success), 1 (error), 2 (partial failure)
- Add `rubocop-rspec` for spec linting
- README overhaul with examples for every subcommand and flag

**Dependencies:** `vcr`, `rubocop-rspec` (development)

---

## 1.0.0 -- Stable Release

Public API is frozen. Semantic versioning contract begins.

- API stability guarantee: breaking changes require a major version bump
- YARD documentation on all public classes and methods
- `CONTRIBUTING.md` with development setup, testing, and architecture overview
- `SECURITY.md` with vulnerability reporting instructions
- Document future Bundler plugin possibility (`bundler-changelog-diff`)

**Dependencies:** `yard` (development)

---
