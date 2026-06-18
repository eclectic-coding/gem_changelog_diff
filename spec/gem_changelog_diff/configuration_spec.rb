# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Configuration do
  after { GemChangelogDiff.reset_configuration! }

  describe "#github_token" do
    it "defaults to nil" do
      expect(described_class.new.github_token).to be_nil
    end

    it "can be set" do
      config = described_class.new
      config.github_token = "ghp_test123"

      expect(config.github_token).to eq("ghp_test123")
    end
  end

  describe "GemChangelogDiff.configuration" do
    it "returns a Configuration instance" do
      expect(GemChangelogDiff.configuration).to be_a(described_class)
    end

    it "returns the same instance on repeated calls" do
      expect(GemChangelogDiff.configuration).to equal(GemChangelogDiff.configuration)
    end
  end

  describe "GemChangelogDiff.configure" do
    it "yields the configuration" do
      GemChangelogDiff.configure do |config|
        config.github_token = "ghp_block_test"
      end

      expect(GemChangelogDiff.configuration.github_token).to eq("ghp_block_test")
    end
  end

  describe "new attribute defaults" do
    it "defaults default_format to text" do
      expect(described_class.new.default_format).to eq("text")
    end

    it "defaults concurrency to 4" do
      expect(described_class.new.concurrency).to eq(4)
    end

    it "defaults ignore_gems to empty array" do
      expect(described_class.new.ignore_gems).to eq([])
    end

    it "defaults no_color to false" do
      expect(described_class.new.no_color).to be false
    end

    it "defaults request_timeout to 10" do
      expect(described_class.new.request_timeout).to eq(10)
    end

    it "defaults total_timeout to 120" do
      expect(described_class.new.total_timeout).to eq(120)
    end
  end

  describe "#apply" do
    it "sets values from a hash" do
      config = described_class.new
      config.apply(concurrency: 8, default_format: "json")

      expect(config.concurrency).to eq(8)
      expect(config.default_format).to eq("json")
    end

    it "skips nil values" do
      config = described_class.new
      config.apply(concurrency: nil)

      expect(config.concurrency).to eq(4)
    end

    it "ignores unknown keys" do
      config = described_class.new

      expect { config.apply(unknown_key: "value") }.not_to raise_error
    end
  end

  describe "GemChangelogDiff.reset_configuration!" do
    it "resets to a fresh configuration" do
      GemChangelogDiff.configuration.github_token = "ghp_old"
      GemChangelogDiff.reset_configuration!

      expect(GemChangelogDiff.configuration.github_token).to be_nil
    end
  end
end
