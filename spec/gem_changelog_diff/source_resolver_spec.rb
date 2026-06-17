# frozen_string_literal: true

RSpec.describe GemChangelogDiff::SourceResolver do
  let(:github_client) { instance_double(GemChangelogDiff::GithubClient) }
  let(:changelog_parser) { instance_double(GemChangelogDiff::ChangelogParser) }

  subject(:resolver) do
    described_class.new(github_client: github_client, changelog_parser: changelog_parser)
  end

  let(:release) do
    { tag_name: "v2.0.0", name: "2.0.0", published_at: "2024-03-01T00:00:00Z", body: "Release notes" }
  end

  let(:changelog_entry) do
    { tag_name: "2.0.0", name: "2.0.0", published_at: nil, body: "- New stuff" }
  end

  describe "#resolve" do
    context "when GitHub releases are available" do
      it "returns releases without trying changelog" do
        allow(github_client).to receive(:releases_between).and_return([release])
        allow(changelog_parser).to receive(:entries_between)

        result = resolver.resolve("owner/repo", "1.0.0", "2.0.0")

        expect(result).to eq([release])
        expect(changelog_parser).not_to have_received(:entries_between)
      end
    end

    context "when GitHub releases are empty" do
      it "falls back to changelog parser" do
        allow(github_client).to receive(:releases_between).and_return([])
        allow(changelog_parser).to receive(:entries_between).and_return([changelog_entry])

        result = resolver.resolve("owner/repo", "1.0.0", "2.0.0")

        expect(result).to eq([changelog_entry])
      end
    end

    context "when both sources are empty" do
      it "returns an empty array" do
        allow(github_client).to receive(:releases_between).and_return([])
        allow(changelog_parser).to receive(:entries_between).and_return([])

        result = resolver.resolve("owner/repo", "1.0.0", "2.0.0")

        expect(result).to eq([])
      end
    end
  end
end
