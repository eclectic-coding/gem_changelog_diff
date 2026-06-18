# frozen_string_literal: true

require "json"

RSpec.describe GemChangelogDiff::Formatters::Json do
  subject(:formatter) { described_class.new }

  let(:gem_info) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  describe "#format" do
    it "returns valid JSON" do
      reports = [{ gem: gem_info, releases: [] }]

      output = formatter.format(reports)

      expect { JSON.parse(output) }.not_to raise_error
    end

    it "includes gem data with correct keys" do
      reports = [{ gem: gem_info, releases: [] }]

      parsed = JSON.parse(formatter.format(reports))

      gem_data = parsed["gems"].first["gem"]
      expect(gem_data["name"]).to eq("rails")
      expect(gem_data["current_version"]).to eq("7.0.8")
      expect(gem_data["newest_version"]).to eq("7.1.3")
    end

    it "includes releases with correct structure" do
      reports = [{
        gem: gem_info,
        releases: [
          { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" }
        ]
      }]

      parsed = JSON.parse(formatter.format(reports))

      release = parsed["gems"].first["releases"].first
      expect(release["tag_name"]).to eq("v7.1.3")
      expect(release["name"]).to eq("7.1.3")
      expect(release["published_at"]).to eq("2024-02-21T00:00:00Z")
      expect(release["body"]).to eq("Bug fixes")
    end

    it "includes error field when present" do
      reports = [{ gem: gem_info, releases: [], error: "  Could not find GitHub repository." }]

      parsed = JSON.parse(formatter.format(reports))

      expect(parsed["gems"].first["error"]).to eq("  Could not find GitHub repository.")
    end

    it "omits error field when not present" do
      reports = [{ gem: gem_info, releases: [] }]

      parsed = JSON.parse(formatter.format(reports))

      expect(parsed["gems"].first).not_to have_key("error")
    end

    it "includes summary counts" do
      reports = [
        { gem: gem_info, releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }] },
        { gem: gem_info, releases: [], error: "  error" }
      ]

      parsed = JSON.parse(formatter.format(reports))

      expect(parsed["summary"]["total"]).to eq(2)
      expect(parsed["summary"]["with_changelogs"]).to eq(1)
      expect(parsed["summary"]["skipped"]).to eq(1)
    end

    it "handles empty reports" do
      parsed = JSON.parse(formatter.format([]))

      expect(parsed["gems"]).to eq([])
      expect(parsed["summary"]["total"]).to eq(0)
    end

    it "handles multiple gems" do
      sidekiq = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                  newest_version: "7.2.0")
      reports = [
        { gem: gem_info, releases: [] },
        { gem: sidekiq, releases: [] }
      ]

      parsed = JSON.parse(formatter.format(reports))

      names = parsed["gems"].map { |g| g["gem"]["name"] }
      expect(names).to eq(%w[rails sidekiq])
    end
  end
end
