# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Formatter do
  subject(:formatter) { described_class.new(color: false) }

  let(:gem_info) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  describe "#format" do
    context "with releases" do
      it "formats the gem header and release details" do
        reports = [{
          gem: gem_info,
          releases: [
            { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" }
          ]
        }]

        output = formatter.format(reports)

        expect(output).to include("== rails (7.0.8 → 7.1.3) ==")
        expect(output).to include("--- v7.1.3 (2024-02-21) ---")
        expect(output).to include("Bug fixes")
      end
    end

    context "with multiple releases" do
      it "includes all releases" do
        reports = [{
          gem: gem_info,
          releases: [
            { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" },
            { tag_name: "v7.1.2", name: "7.1.2", published_at: "2024-01-16T00:00:00Z", body: "Security patch" }
          ]
        }]

        output = formatter.format(reports)

        expect(output).to include("v7.1.3")
        expect(output).to include("v7.1.2")
      end
    end

    context "with no releases" do
      it "shows no changelog entries found message" do
        reports = [{ gem: gem_info, releases: [] }]

        output = formatter.format(reports)

        expect(output).to include("No changelog entries found.")
      end
    end

    context "with an error message" do
      it "shows the error message" do
        reports = [{ gem: gem_info, releases: [], error: "  Could not find GitHub repository." }]

        output = formatter.format(reports)

        expect(output).to include("Could not find GitHub repository.")
      end
    end

    context "with a nil release body" do
      it "shows no release notes placeholder" do
        reports = [{
          gem: gem_info,
          releases: [
            { tag_name: "v7.1.3", name: "7.1.3", published_at: "2024-02-21T00:00:00Z", body: nil }
          ]
        }]

        output = formatter.format(reports)

        expect(output).to include("(no release notes)")
      end
    end

    context "with multiple gems" do
      it "formats each gem separately" do
        sidekiq = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                    newest_version: "7.2.0")
        reports = [
          { gem: gem_info, releases: [] },
          { gem: sidekiq, releases: [] }
        ]

        output = formatter.format(reports)

        expect(output).to include("== rails (7.0.8 → 7.1.3) ==")
        expect(output).to include("== sidekiq (7.1.0 → 7.2.0) ==")
      end
    end
  end

  describe "summary line" do
    it "includes gem counts" do
      reports = [
        { gem: gem_info, releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }] },
        { gem: gem_info, releases: [], error: "  Could not find GitHub repository." }
      ]

      output = formatter.format(reports)

      expect(output).to include("2 gems outdated, 1 with changelogs found, 1 skipped")
    end
  end

  describe "color support" do
    it "applies ANSI codes when color is enabled" do
      colored_formatter = described_class.new(color: true)
      reports = [{
        gem: gem_info,
        releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }]
      }]

      output = colored_formatter.format(reports)

      expect(output).to include("\e[1m\e[36m")
      expect(output).to include("\e[33m")
      expect(output).to include("\e[0m")
    end

    it "does not apply ANSI codes when color is disabled" do
      reports = [{
        gem: gem_info,
        releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }]
      }]

      output = formatter.format(reports)

      expect(output).not_to include("\e[")
    end

    it "respects NO_COLOR env var in default_color?" do
      allow(TTY::Color).to receive(:color?).and_return(true)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("NO_COLOR", nil).and_return("1")

      no_color_formatter = described_class.new

      reports = [{
        gem: gem_info,
        releases: [{ tag_name: "v7.1.3", name: "7.1.3", published_at: nil, body: "notes" }]
      }]

      output = no_color_formatter.format(reports)

      expect(output).not_to include("\e[")
    end
  end
end
