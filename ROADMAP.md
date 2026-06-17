# Roadmap

Feature roadmap for gem_changelog_diff. Each section is auto-pruned by `bin/release` when that version ships.

## 0.1.0 -- MVP: End-to-End Proof of Value

Ship the core pipeline so a user can run `gem_changelog_diff` and see changelog diffs for outdated gems.

- ~~CLI entry point via Thor (`exe/gem_changelog_diff`)~~
- ~~Detect outdated gems by parsing `bundle outdated --parseable`~~
- ~~Look up each gem's GitHub repository via the RubyGems API (`/api/v1/gems/{name}.json`)~~
- ~~Fetch GitHub releases between locked and latest versions via `net/http`~~
- Plain text output to stdout

**New files:** `exe/gem_changelog_diff`, `cli.rb`, `detector.rb`, `rubygems_client.rb`, `github_client.rb`, `formatter.rb`
**Dependencies:** `thor ~> 1.0` (runtime), `webmock` (test)

---

## 0.2.0 -- Error Handling & GitHub Authentication

Handle real-world failures and unblock power users hitting the 60 req/hr unauthenticated rate limit.

- GitHub personal access token via `--token` flag or `GITHUB_TOKEN` env var
- Custom error hierarchy (`RepoNotFoundError`, `GitHubAPIError`, `RateLimitError`, `NetworkError`)
- Graceful degradation: skip failed gems with a warning, do not abort the run
- Rate limit awareness: read `X-RateLimit-Remaining` headers, warn when approaching the limit
- `--verbose` and `--quiet` flags

**New files:** `errors.rb`, `configuration.rb`

---

## 0.3.0 -- CHANGELOG.md Fallback & Colored Output

Many gems do not use GitHub Releases. Fall back to parsing CHANGELOG.md from the repository.

- Fetch raw CHANGELOG.md via GitHub Contents API; try common variants (`CHANGELOG.md`, `CHANGES.md`, `History.md`, `NEWS.md`)
- Parse Keep-a-Changelog and common freeform formats; extract entries between current and target versions
- Colorized terminal output via `tty-color` (gem names, versions, warnings); respect `$NO_COLOR` and `--no-color`
- Summary line: "X gems outdated, Y with changelogs found, Z skipped"

**New files:** `changelog_parser.rb`, `source_resolver.rb`
**Dependencies:** `tty-color` (runtime)

---

## 0.4.0 -- Lockfile Parsing Fallback & Filtering

Support environments where `bundle outdated` is unavailable. Let users narrow which gems to inspect.

- Parse `Gemfile.lock` directly via `Bundler::LockfileParser` and query RubyGems API for latest versions
- Automatic fallback when `bundle outdated` fails
- Positional args to inspect specific gems: `gem_changelog_diff check rails sidekiq`
- `--group`, `--ignore`, `--lockfile`, `--strategy` flags

**New files:** `lockfile_parser.rb`

---

## 0.5.0 -- Caching & Performance

Avoid redundant API calls. Make repeated runs fast on large dependency trees.

- Disk cache at `~/.cache/gem_changelog_diff/` with configurable TTL (default 24h)
- ETag conditional requests to avoid consuming rate limit on revalidation
- Concurrent fetching via Ruby threads (default concurrency: 4, configurable via `--concurrency`)
- Progress indicator via `tty-spinner`
- `cache clear` subcommand, `--no-cache` and `--cache-ttl` flags

**New files:** `cache.rb`, `concurrent_fetcher.rb`
**Dependencies:** `tty-spinner` (runtime)

---

## 0.6.0 -- Interactive Mode & Output Formats

Let users selectively browse changelogs. Support machine-readable output for CI and scripting.

- Interactive gem selection via `tty-prompt` (`--interactive` / `-i` flag)
- JSON output (`--format=json`) for piping to `jq` or CI tools
- Markdown output (`--format=markdown`) for PR descriptions
- `show` subcommand: `gem_changelog_diff show rails 7.0.0 7.1.0`
- `--output` flag to write to a file

**New files:** `interactive.rb`, `formatters/base.rb`, `formatters/text.rb`, `formatters/json.rb`, `formatters/markdown.rb`
**Dependencies:** `tty-prompt` (runtime)

---

## 0.7.0 -- Configuration File & Polish

Persistent preferences so users don't repeat flags every run.

- Config file: `.gem_changelog_diff.yml` (project root) and `~/.config/gem_changelog_diff/config.yml` (user); project overrides user
- Supported keys: `github_token`, `default_format`, `cache_ttl`, `concurrency`, `ignore_gems`, `no_color`
- `init` subcommand: generate a commented config template
- `version` subcommand
- `--dry-run` flag: show which gems would be checked without fetching

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