# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

gem_changelog_diff is a Ruby gem CLI that shows changelog diffs for each gem before you `bundle update`, pulled from GitHub releases. Requires Ruby >= 3.3.

## Commands

```bash
bundle exec rake              # Run all checks (bundler-audit, rubocop, rspec)
bundle exec rake spec         # Run tests only
bundle exec rspec spec/path_spec.rb        # Run a single test file
bundle exec rspec spec/path_spec.rb:42     # Run a single example by line
bundle exec rubocop           # Lint
bundle exec rubocop -a        # Lint with auto-correct
bundle exec rake bundle:audit:check        # Security audit
```

## Workflow

All feature work lives on `feature/<version>-<scope>` branches (e.g. `feature/0.1.0-core`). Every branch produces two commits before pushing:

1. **Feature commit** — implementation + specs. Run `bundle exec rake` and fix all failures before committing.
2. **Docs commit** — add shipped items to `CHANGELOG.md`, remove them from `ROADMAP.md`, update `README.md`. Run `bundle exec rake` again before this commit.

## Code Style

- RuboCop with `rubocop-rake` plugin; double quotes for strings
- Target Ruby version: 3.3
- `frozen_string_literal: true` on all Ruby files
- `Style/Documentation` is disabled

## Testing

- RSpec with `--format documentation`
- SimpleCov for coverage (HTML + JSON output); JSON uploaded to Codecov in CI
- Coverage filters: `spec/` and `version.rb` excluded; tracks `lib/**/*.rb`

## CI

GitHub Actions runs on push to main and PRs: Lint, Security audit, and tests across Ruby 3.3, 3.4, and 4.0. Branch protection requires all five jobs to pass.

## Releasing

Update `lib/gem_changelog_diff/version.rb`, tag with `v*`, and push. The publish workflow runs tests, creates a GitHub Release, and publishes to RubyGems via trusted publishing.