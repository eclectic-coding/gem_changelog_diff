# frozen_string_literal: true

module GemChangelogDiff
  class SourceResolver
    def initialize(github_client: GithubClient.new, changelog_parser: ChangelogParser.new)
      @github_client = github_client
      @changelog_parser = changelog_parser
    end

    def resolve(repo, current_version, newest_version)
      releases = @github_client.releases_between(repo, current_version, newest_version)
      return releases unless releases.empty?

      @changelog_parser.entries_between(repo, current_version, newest_version)
    end
  end
end
