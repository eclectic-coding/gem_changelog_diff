# frozen_string_literal: true

require_relative "gem_changelog_diff/version"
require_relative "gem_changelog_diff/configuration"
require_relative "gem_changelog_diff/config_loader"

module GemChangelogDiff
  class Error < StandardError; end
end

require_relative "gem_changelog_diff/errors"
require_relative "gem_changelog_diff/cache"
require_relative "gem_changelog_diff/outdated_gem"
require_relative "gem_changelog_diff/detector"
require_relative "gem_changelog_diff/uri_resolver"
require_relative "gem_changelog_diff/tag_matcher"
require_relative "gem_changelog_diff/rubygems_client"
require_relative "gem_changelog_diff/lockfile_parser"
require_relative "gem_changelog_diff/github_client"
require_relative "gem_changelog_diff/changelog_parser"
require_relative "gem_changelog_diff/source_resolver"
require_relative "gem_changelog_diff/concurrent_fetcher"
require_relative "gem_changelog_diff/formatters/base"
require_relative "gem_changelog_diff/formatters/text"
require_relative "gem_changelog_diff/formatters/json"
require_relative "gem_changelog_diff/formatters/markdown"
require_relative "gem_changelog_diff/formatter"
require_relative "gem_changelog_diff/interactive"
require_relative "gem_changelog_diff/cli"
