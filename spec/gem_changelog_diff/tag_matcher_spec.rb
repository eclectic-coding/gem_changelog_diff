# frozen_string_literal: true

RSpec.describe GemChangelogDiff::TagMatcher do
  describe "#extract_version" do
    context "with standard patterns" do
      subject(:matcher) { described_class.new }

      it "extracts version from v-prefixed tag" do
        expect(matcher.extract_version("v1.2.3")).to eq("1.2.3")
      end

      it "extracts bare version tag" do
        expect(matcher.extract_version("1.2.3")).to eq("1.2.3")
      end

      it "extracts version from release-prefixed tag" do
        expect(matcher.extract_version("release-1.2.3")).to eq("1.2.3")
      end

      it "extracts version from release-v-prefixed tag" do
        expect(matcher.extract_version("release-v1.2.3")).to eq("1.2.3")
      end

      it "handles pre-release versions" do
        expect(matcher.extract_version("v2.0.0.beta1")).to eq("2.0.0.beta1")
      end

      it "handles four-segment versions" do
        expect(matcher.extract_version("v1.2.3.4")).to eq("1.2.3.4")
      end
    end

    context "with gem-prefixed tags" do
      subject(:matcher) { described_class.new(gem_name: "nokogiri") }

      it "extracts version from gem_name-version tag" do
        expect(matcher.extract_version("nokogiri-1.16.0")).to eq("1.16.0")
      end

      it "extracts version from gem_name-v-version tag" do
        expect(matcher.extract_version("nokogiri-v1.16.0")).to eq("1.16.0")
      end

      it "falls back to standard pattern when prefix does not match" do
        expect(matcher.extract_version("v1.2.3")).to eq("1.2.3")
      end
    end

    context "with nil gem_name" do
      subject(:matcher) { described_class.new(gem_name: nil) }

      it "skips gem-prefixed matching" do
        expect(matcher.extract_version("v1.0.0")).to eq("1.0.0")
      end
    end

    context "with invalid inputs" do
      subject(:matcher) { described_class.new }

      it "returns nil for nil" do
        expect(matcher.extract_version(nil)).to be_nil
      end

      it "returns nil for empty string" do
        expect(matcher.extract_version("")).to be_nil
      end

      it "returns nil for whitespace-only string" do
        expect(matcher.extract_version("   ")).to be_nil
      end

      it "returns nil for non-version tag" do
        expect(matcher.extract_version("latest")).to be_nil
      end

      it "returns nil for malformed version" do
        expect(matcher.extract_version("v.not.a.version")).to be_nil
      end

      it "returns nil when version matches pattern but fails Gem::Version" do
        expect(matcher.extract_version("v1.2.3 bad")).to be_nil
      end
    end
  end
end
