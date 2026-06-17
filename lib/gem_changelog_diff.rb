# frozen_string_literal: true

require_relative "gem_changelog_diff/version"
require_relative "gem_changelog_diff/outdated_gem"
require_relative "gem_changelog_diff/detector"
require_relative "gem_changelog_diff/rubygems_client"
require_relative "gem_changelog_diff/github_client"
require_relative "gem_changelog_diff/formatter"
require_relative "gem_changelog_diff/cli"

module GemChangelogDiff
  class Error < StandardError; end
end
