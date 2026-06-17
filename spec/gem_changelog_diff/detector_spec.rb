# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Detector do
  subject(:detector) { described_class.new }

  describe "#detect" do
    context "when gems are outdated" do
      it "parses gems from bundle outdated output" do
        output = <<~OUTPUT
          rails (newest 7.1.3, installed 7.0.8, requested ~> 7.0)
          sidekiq (newest 7.2.0, installed 7.1.0)
        OUTPUT
        status = instance_double(Process::Status, exitstatus: 1)
        allow(Open3).to receive(:capture2).with("bundle", "outdated", "--parseable").and_return([output, status])

        gems = detector.detect

        expect(gems).to eq([
          GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3"),
          GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0", newest_version: "7.2.0")
        ])
      end
    end

    context "when all gems are up to date" do
      it "returns an empty array" do
        status = instance_double(Process::Status, exitstatus: 0)
        allow(Open3).to receive(:capture2).with("bundle", "outdated", "--parseable").and_return(["", status])

        expect(detector.detect).to eq([])
      end
    end

    context "when bundle outdated fails" do
      it "raises an error" do
        status = instance_double(Process::Status, exitstatus: 2)
        allow(Open3).to receive(:capture2).with("bundle", "outdated", "--parseable").and_return(["", status])

        expect { detector.detect }.to raise_error(GemChangelogDiff::Error, /bundle outdated failed/)
      end
    end

    context "with non-matching lines in output" do
      it "skips blank lines and progress messages" do
        output = <<~OUTPUT

          Fetching gem metadata...
          rails (newest 7.1.3, installed 7.0.8)

        OUTPUT
        status = instance_double(Process::Status, exitstatus: 1)
        allow(Open3).to receive(:capture2).with("bundle", "outdated", "--parseable").and_return([output, status])

        gems = detector.detect

        expect(gems.size).to eq(1)
        expect(gems.first.name).to eq("rails")
      end
    end
  end
end