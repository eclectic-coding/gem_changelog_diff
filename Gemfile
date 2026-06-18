# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in gem_changelog_diff.gemspec
gemspec

gem "rake", "~> 13.0"

group :development do
  gem "bundler-audit"
  gem "irb"
  gem "rubocop", "~> 1.21"
  gem "rubocop-rake"
  gem "rubocop-rspec"
  gem "yard", require: false
end

group :test do
  gem "rspec", "~> 3.0"
  gem "simplecov", require: false
  gem "simplecov_json_formatter", require: false
  gem "vcr", "~> 6.0"
  gem "webmock", "~> 3.0"
end
