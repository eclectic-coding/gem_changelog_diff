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
- [Development](#development)
- [Contributing](#contributing)
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

### GitHub Authentication

To avoid the 60 requests/hour unauthenticated rate limit, provide a GitHub personal access token:

```bash
gem_changelog_diff --token ghp_your_token
# or
export GITHUB_TOKEN=ghp_your_token
gem_changelog_diff
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

[Back to top](#gemchangelogdiff)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

[Back to top](#gemchangelogdiff)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eclectic-coding/gem_changelog_diff.

[Back to top](#gemchangelogdiff)

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
