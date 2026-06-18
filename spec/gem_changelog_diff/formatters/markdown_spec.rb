# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Formatters::Markdown do
  subject(:formatter) { described_class.new }

  let(:gem_info) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  describe "#format" do
    it "uses markdown headings for gem headers" do
      reports = [{ gem: gem_info, releases: [] }]

      output = formatter.format(reports)

      expect(output).to include("## rails (7.0.8 → 7.1.3)")
    end

    it "uses subheadings for releases" do
      reports = [{
        gem: gem_info,
        releases: [
          { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" }
        ]
      }]

      output = formatter.format(reports)

      expect(output).to include("### v7.1.3 (2024-02-21)")
      expect(output).to include("Bug fixes")
    end

    it "shows no changelog message when no releases" do
      reports = [{ gem: gem_info, releases: [] }]

      output = formatter.format(reports)

      expect(output).to include("No changelog entries found.")
    end

    it "shows error message when present" do
      reports = [{ gem: gem_info, releases: [], error: "  Could not find GitHub repository." }]

      output = formatter.format(reports)

      expect(output).to include("Could not find GitHub repository.")
    end

    it "shows placeholder for nil release body" do
      reports = [{
        gem: gem_info,
        releases: [
          { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: nil }
        ]
      }]

      output = formatter.format(reports)

      expect(output).to include("*(no release notes)*")
    end

    it "includes italic summary line" do
      reports = [
        { gem: gem_info, releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }] },
        { gem: gem_info, releases: [], error: "  error" }
      ]

      output = formatter.format(reports)

      expect(output).to include("_2 gems outdated, 1 with changelogs found, 1 skipped_")
    end

    it "formats multiple gems separately" do
      sidekiq = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                  newest_version: "7.2.0")
      reports = [
        { gem: gem_info, releases: [] },
        { gem: sidekiq, releases: [] }
      ]

      output = formatter.format(reports)

      expect(output).to include("## rails (7.0.8 → 7.1.3)")
      expect(output).to include("## sidekiq (7.1.0 → 7.2.0)")
    end
  end
end
