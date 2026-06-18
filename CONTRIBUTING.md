# Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/eclectic-coding/gem_changelog_diff.

## Development Setup

```bash
git clone https://github.com/eclectic-coding/gem_changelog_diff.git
cd gem_changelog_diff
bin/setup
```

## Running Tests

```bash
bundle exec rake              # Run all checks (rubocop, bundler-audit, rspec)
bundle exec rake spec         # Run tests only
bundle exec rspec spec/path_spec.rb        # Run a single file
bundle exec rspec spec/path_spec.rb:42     # Run a single example
```

Integration tests use VCR cassettes committed to the repo. To re-record:

```bash
GITHUB_TOKEN=ghp_... bundle exec rspec spec/integration/
```

## Linting

```bash
bundle exec rubocop           # Check style
bundle exec rubocop -a        # Auto-correct
```

## Architecture

The pipeline flows through these stages:

1. **Detection** -- `Detector` runs `bundle outdated` (or `LockfileParser` reads `Gemfile.lock`) to find outdated gems
2. **Resolution** -- `RubygemsClient` queries the RubyGems API, `UriResolver` extracts the GitHub slug
3. **Fetching** -- `GithubClient` fetches releases from the GitHub API; `ChangelogParser` parses `CHANGELOG.md` as a fallback. `SourceResolver` orchestrates both
4. **Concurrency** -- `ConcurrentFetcher` runs fetches in a thread pool
5. **Formatting** -- `Formatters::Text`, `Json`, or `Markdown` render the output
6. **CLI** -- `CLI` (Thor) ties everything together with flags, config, and exit codes

## Branch Workflow

All feature work lives on `feature/<version>-<scope>` branches. Every branch produces two commits:

1. **Feature commit** -- implementation + specs. Run `bundle exec rake` and fix all failures before committing.
2. **Docs commit** -- update `CHANGELOG.md`, remove shipped items from `ROADMAP.md`, update `README.md` if needed.

## Pull Request Requirements

- All CI checks must pass (lint, security audit, tests on Ruby 3.3, 3.4, and 4.0)
- 100% line coverage required
- RuboCop must report zero offenses
