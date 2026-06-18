# frozen_string_literal: true

RSpec.describe "Edge cases" do
  let(:cache) { GemChangelogDiff::Cache.new(enabled: false) }
  let(:rubygems_client) { GemChangelogDiff::RubygemsClient.new(cache: cache) }

  after { GemChangelogDiff.reset_configuration! }

  describe "when gem is hosted on non-GitHub platform" do
    it "raises RepoNotFoundError for GitLab gems",
       vcr: { cassette_name: "integration/gitlab_gem" } do
      expect { rubygems_client.repo_url("gitlab_omniauth-ldap") }
        .to raise_error(GemChangelogDiff::RepoNotFoundError, /GitLab/)
    end
  end

  describe "when gem has no GitHub Releases" do
    it "falls back to changelog parsing without error",
       vcr: { cassette_name: "integration/sidekiq_changelog_fallback" } do
      github_client = GemChangelogDiff::GithubClient.new(cache: cache)
      changelog_parser = GemChangelogDiff::ChangelogParser.new(cache: cache)
      source_resolver = GemChangelogDiff::SourceResolver.new(
        github_client: github_client,
        changelog_parser: changelog_parser
      )

      repo = rubygems_client.repo_url("sidekiq")
      releases = source_resolver.resolve(repo, "7.2.0", "7.3.0")

      expect(releases).to be_an(Array)
    end
  end
end
