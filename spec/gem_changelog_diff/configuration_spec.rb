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

  describe "GemChangelogDiff.reset_configuration!" do
    it "resets to a fresh configuration" do
      GemChangelogDiff.configuration.github_token = "ghp_old"
      GemChangelogDiff.reset_configuration!

      expect(GemChangelogDiff.configuration.github_token).to be_nil
    end
  end
end
