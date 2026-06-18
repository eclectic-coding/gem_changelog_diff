# frozen_string_literal: true

RSpec.describe "Formatter integration" do
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
  let(:gem_info) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  after { GemChangelogDiff.reset_configuration! }

  def build_report
    repo = rubygems_client.repo_url("rails")
    releases = source_resolver.resolve(repo, "7.0.8", "7.1.3")
    { gem: gem_info, releases: releases }
  end

  describe "text format" do
    it "produces readable output", vcr: { cassette_name: "integration/rails_releases" } do
      report = build_report
      formatter = GemChangelogDiff::Formatters.build(format: "text", color: false)
      output = formatter.format([report])

      expect(output).to include("rails (7.0.8")
      expect(output).to include("v7.1.3")
    end
  end

  describe "json format" do
    it "produces valid parseable JSON", vcr: { cassette_name: "integration/rails_releases" } do
      report = build_report
      formatter = GemChangelogDiff::Formatters.build(format: "json")
      output = formatter.format([report])

      parsed = JSON.parse(output)

      expect(parsed["gems"].first["gem"]["name"]).to eq("rails")
      expect(parsed["gems"].first["releases"]).not_to be_empty
    end
  end

  describe "markdown format" do
    it "produces markdown with headings", vcr: { cassette_name: "integration/rails_releases" } do
      report = build_report
      formatter = GemChangelogDiff::Formatters.build(format: "markdown")
      output = formatter.format([report])

      expect(output).to include("## rails")
      expect(output).to include("### v7.1.3")
    end
  end
end
