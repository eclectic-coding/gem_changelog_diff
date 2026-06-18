# frozen_string_literal: true

RSpec.describe "Full pipeline" do
  let(:cache) { GemChangelogDiff::Cache.new(enabled: false) }
  let(:rubygems_client) { GemChangelogDiff::RubygemsClient.new(cache: cache) }
  let(:github_client) { GemChangelogDiff::GithubClient.new(cache: cache) }
  let(:changelog_parser) { GemChangelogDiff::ChangelogParser.new(cache: cache) }
  let(:source_resolver) do
    GemChangelogDiff::SourceResolver.new(
      github_client: github_client,
      changelog_parser: changelog_parser
    )
  end

  after { GemChangelogDiff.reset_configuration! }

  describe "rails" do
    it "fetches releases with v-prefixed tags",
       vcr: { cassette_name: "integration/rails_releases" } do
      repo = rubygems_client.repo_url("rails")

      expect(repo).to eq("rails/rails")

      releases = source_resolver.resolve(repo, "7.0.8", "7.1.3")
      tag_names = releases.map { |r| r[:tag_name] }

      expect(tag_names).to include("v7.1.3")
      expect(tag_names).not_to include("v7.0.8")
    end
  end

  describe "nokogiri" do
    it "handles gem-prefixed tags",
       vcr: { cassette_name: "integration/nokogiri_releases" } do
      repo = rubygems_client.repo_url("nokogiri")

      expect(repo).to eq("sparklemotion/nokogiri")

      releases = source_resolver.resolve(repo, "1.15.0", "1.16.0")

      expect(releases).not_to be_empty
    end
  end

  describe "puma" do
    it "fetches releases with standard tags",
       vcr: { cassette_name: "integration/puma_releases" } do
      repo = rubygems_client.repo_url("puma")

      expect(repo).to eq("puma/puma")

      releases = source_resolver.resolve(repo, "6.4.0", "6.5.0")

      expect(releases).not_to be_empty
    end
  end
end
