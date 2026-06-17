# GemChangelogDiff

[![CI](https://github.com/eclectic-coding/gem_changelog_diff/actions/workflows/main.yml/badge.svg)](https://github.com/eclectic-coding/gem_changelog_diff/actions/workflows/main.yml)
[![Gem Version](https://img.shields.io/gem/v/gem_changelog_diff)](https://rubygems.org/gems/gem_changelog_diff)
[![Gem Downloads](https://img.shields.io/gem/dt/gem_changelog_diff)](https://rubygems.org/gems/gem_changelog_diff)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3.0-ruby)](https://www.ruby-lang.org)
[![Codecov](https://img.shields.io/codecov/c/github/eclectic-coding/gem_changelog_diff)](https://codecov.io/gh/eclectic-coding/gem_changelog_diff)

CLI that shows you the changelog diff for each gem before you `bundle update`, pulled from GitHub releases.

## Installation

Install the gem by executing:

```bash
gem install gem_changelog_diff
```

Or add it to your Gemfile:

```bash
bundle add gem_changelog_diff
```

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

### Output Control

```bash
gem_changelog_diff --verbose  # Show detailed status messages
gem_changelog_diff --quiet    # Suppress warnings
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eclectic-coding/gem_changelog_diff.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).