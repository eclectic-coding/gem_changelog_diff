# frozen_string_literal: true

RSpec.describe GemChangelogDiff::CLI do
  describe "#check" do
    context "when gems are outdated" do
      it "prints outdated gem names with versions" do
        gems = [
          GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
        ]
        detector = instance_double(GemChangelogDiff::Detector, detect: gems)
        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("rails (7.0.8 → 7.1.3)")
      end
    end

    context "when all gems are up to date" do
      it "prints up to date message" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [])
        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("All gems are up to date!")
      end
    end
  end

  describe "#version" do
    it "prints the version" do
      output = capture_output { described_class.start(["version"]) }

      expect(output).to include("gem_changelog_diff #{GemChangelogDiff::VERSION}")
    end
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end