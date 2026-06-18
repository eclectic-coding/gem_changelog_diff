# GemChangelogDiff

[![CI](https://github.com/eclectic-coding/gem_changelog_diff/actions/workflows/main.yml/badge.svg)](https://github.com/eclectic-coding/gem_changelog_diff/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/gem_changelog_diff)](https://rubygems.org/gems/gem_changelog_diff)
[![Gem Downloads](https://img.shields.io/gem/dt/gem_changelog_diff)](https://rubygems.org/gems/gem_changelog_diff)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3.0-ruby)](https://www.ruby-lang.org)
[![Codecov](https://img.shields.io/codecov/c/github/eclectic-coding/gem_changelog_diff)](https://codecov.io/gh/eclectic-coding/gem_changelog_diff)

CLI that shows you the changelog diff for each gem before you `bundle update`, pulled from GitHub releases.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [GitHub Authentication](#github-authentication)
  - [Output Formats](#output-formats)
  - [Output Control](#output-control)
  - [Detection Strategy](#detection-strategy)
  - [Filtering](#filtering)
  - [Interactive Mode](#interactive-mode)
  - [Show Subcommand](#show-subcommand)
  - [Caching](#caching)
  - [Dry Run](#dry-run)
  - [Timeouts](#timeouts)
  - [Concurrency](#concurrency)
  - [Exit Codes](#exit-codes)
- [Configuration File](#configuration-file)
- [Stability](#stability)
- [Development](#development)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## Installation

Install the gem by executing:

```bash
gem install gem_changelog_diff
```

Or add it to your Gemfile:

```bash
bundle add gem_changelog_diff
```

[Back to top](#gemchangelogdiff)

## Usage

```bash
gem_changelog_diff
```

Run from a project directory with a `Gemfile.lock`. The tool detects outdated gems via `bundle outdated`, looks up their GitHub repositories, fetches release notes, and displays a formatted changelog diff.

```bash
gem_changelog_diff version    # Print version
gem_changelog_diff --version  # Same as above
```

### Non-GitHub Gems

Gems hosted on GitHub are fully supported. Gems on other platforms (GitLab, Codeberg, Bitbucket, SourceHut) are detected and skipped with an informative message. Renamed GitHub repositories are followed automatically via redirect.

### GitHub Authentication

To avoid the 60 requests/hour unauthenticated rate limit, provide a GitHub personal access token:

```bash
gem_changelog_diff --token ghp_your_token
# or
export GITHUB_TOKEN=ghp_your_token
gem_changelog_diff
```

Token resolution priority: `--token` flag → `GITHUB_TOKEN` env → `gh auth token` → Rails credentials → config file.

#### GitHub CLI

If you have the [GitHub CLI](https://cli.github.com/) installed and authenticated (`gh auth login`), the token is picked up automatically — no configuration needed.

#### Rails Credentials

When running inside a Rails app, the token is automatically read from Rails credentials:

```ruby
Rails.application.credentials.dig(:gem_changelog_diff, :github_token)
```

Set it via `rails credentials:edit`:

```yaml
gem_changelog_diff:
  github_token: ghp_your_token
```

### Output Formats

```bash
gem_changelog_diff --format text      # Plain text with ANSI colors (default)
gem_changelog_diff --format json      # JSON for piping to jq or CI tools
gem_changelog_diff --format markdown  # Markdown for PR descriptions
gem_changelog_diff --output report.md --format markdown  # Write to a file
```

### Output Control

```bash
gem_changelog_diff --verbose   # Show detailed status messages
gem_changelog_diff --quiet     # Suppress warnings
gem_changelog_diff --no-color  # Disable colored output
```

The tool also respects the `$NO_COLOR` environment variable.

### Detection Strategy

```bash
gem_changelog_diff --strategy lockfile   # Parse Gemfile.lock directly
gem_changelog_diff --strategy outdated   # Use bundle outdated only
gem_changelog_diff --strategy auto       # Try bundle outdated, fallback to lockfile (default)
gem_changelog_diff --lockfile path/to/Gemfile.lock  # Custom lockfile path
```

### Filtering

```bash
gem_changelog_diff check rails sidekiq  # Only check specific gems
gem_changelog_diff --group development   # Filter by Bundler group
gem_changelog_diff --ignore rails rake   # Exclude specific gems
```

### Interactive Mode

```bash
gem_changelog_diff --interactive  # Multi-select which gems to check
gem_changelog_diff -i             # Short alias
```

After detecting outdated gems, presents a multi-select prompt where you can choose which gems to fetch changelogs for.

### Show Subcommand

Look up changelogs for a specific gem between two versions, without needing a Gemfile.lock:

```bash
gem_changelog_diff show rails 7.0.8 7.1.3
gem_changelog_diff show rails 7.0.8 7.1.3 --format json
```

### Caching

API responses are cached to `~/.cache/gem_changelog_diff/` with a 24-hour TTL. Subsequent runs reuse cached data and use ETag conditional requests to avoid consuming rate limit.

```bash
gem_changelog_diff --no-cache             # Bypass the cache
gem_changelog_diff --cache-ttl 3600       # Set TTL to 1 hour
gem_changelog_diff cache clear            # Clear all cached data
```

### Dry Run

Preview which gems would be checked without fetching changelogs:

```bash
gem_changelog_diff --dry-run                     # List gems in text format
gem_changelog_diff --dry-run --format json       # JSON array of gem objects
gem_changelog_diff --dry-run --format markdown   # Markdown bullet list
```

### Timeouts

```bash
gem_changelog_diff --timeout 30  # Per-request timeout in seconds (default: 10)
```

The total operation timeout (default: 120s) limits how long concurrent fetching can run. Both values are configurable via the config file.

### Concurrency

```bash
gem_changelog_diff --concurrency 8   # Fetch 8 gems in parallel (default: 4)
gem_changelog_diff --concurrency 1   # Disable concurrent fetching
```

The concurrency setting controls how many gems are fetched simultaneously using threads. Lower values reduce load on the GitHub API; higher values speed up large projects.

### Exit Codes

The CLI uses defined exit codes for scripting and CI integration:

| Code | Meaning |
|------|---------|
| 0 | All gems processed successfully |
| 1 | Complete failure (all gems failed, or fatal error) |
| 2 | Some gems succeeded, some failed |

The `check` command sets the exit code based on how many gems produced errors:

```bash
gem_changelog_diff check
echo $?  # 0 = all ok, 1 = all failed, 2 = some failed
```

The `show` command exits 0 on success or 1 if the changelog could not be retrieved:

```bash
gem_changelog_diff show rails 7.0.8 7.1.3
echo $?  # 0 = success, 1 = error
```

#### CI Integration

Use exit codes to control CI behavior:

```bash
# Fail CI only on complete failure
gem_changelog_diff check || [ $? -eq 2 ]

# Strict mode: fail on any error
gem_changelog_diff check
```

### Configuration File

Generate a config file template:

```bash
gem_changelog_diff init  # Creates .gem_changelog_diff.yml
```

The tool loads settings from two locations (project overrides user):

1. `~/.config/gem_changelog_diff/config.yml` (user-level defaults)
2. `.gem_changelog_diff.yml` (project-level overrides)

Supported keys:

```yaml
github_token: ghp_xxx
default_format: text       # text, json, markdown
cache_ttl: 86400           # seconds (default: 24 hours)
concurrency: 4
ignore_gems:
  - rake
  - bundler
no_color: false
request_timeout: 10        # per-request timeout in seconds
total_timeout: 120         # total operation timeout in seconds
```

CLI flags always take priority over config file values.

[Back to top](#gemchangelogdiff)

## Stability

Starting with version 1.0.0, this gem follows [Semantic Versioning](https://semver.org/). The public API is frozen — breaking changes require a major version bump.

A future Bundler plugin (`bundler-changelog-diff`) may provide deeper integration, but the standalone CLI will remain the primary interface.

[Back to top](#gemchangelogdiff)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

[Back to top](#gemchangelogdiff)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eclectic-coding/gem_changelog_diff. See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

[Back to top](#gemchangelogdiff)

## Security

To report a security vulnerability, see [SECURITY.md](SECURITY.md).

[Back to top](#gemchangelogdiff)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
