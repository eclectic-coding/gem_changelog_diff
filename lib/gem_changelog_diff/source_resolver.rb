# frozen_string_literal: true

module GemChangelogDiff
  # Fetches release notes, trying GitHub Releases first then changelog files.
  class SourceResolver
    def initialize(github_client: GithubClient.new, changelog_parser: ChangelogParser.new)
      @github_client = github_client
      @changelog_parser = changelog_parser
    end

    # Returns release entries between two versions for a given repo.
    # @param repo [String] GitHub "owner/repo" slug
    # @param current_version [String] currently locked version (exclusive)
    # @param newest_version [String] target version (inclusive)
    # @return [Array<Hash>] release hashes with :tag_name, :name, :published_at, :body
    def resolve(repo, current_version, newest_version)
      releases = @github_client.releases_between(repo, current_version, newest_version)
      return releases unless releases.empty?

      @changelog_parser.entries_between(repo, current_version, newest_version)
    end
  end
end
