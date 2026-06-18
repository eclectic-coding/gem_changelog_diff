# frozen_string_literal: true

# rubocop:disable RSpec/MultipleDescribes -- Base and Formatters.build are tightly related
RSpec.describe GemChangelogDiff::Formatters::Base do
  describe "#format" do
    it "raises NotImplementedError" do
      base = described_class.new

      expect { base.format([]) }.to raise_error(NotImplementedError)
    end
  end
end

RSpec.describe GemChangelogDiff::Formatters do
  describe ".build" do
    it "returns a Text formatter for 'text'" do
      formatter = described_class.build(format: "text", color: false)

      expect(formatter).to be_a(GemChangelogDiff::Formatters::Text)
    end

    it "returns a Json formatter for 'json'" do
      formatter = described_class.build(format: "json")

      expect(formatter).to be_a(GemChangelogDiff::Formatters::Json)
    end

    it "returns a Markdown formatter for 'markdown'" do
      formatter = described_class.build(format: "markdown")

      expect(formatter).to be_a(GemChangelogDiff::Formatters::Markdown)
    end

    it "raises ArgumentError for unknown format" do
      expect { described_class.build(format: "xml") }.to raise_error(ArgumentError, /Unknown format: xml/)
    end
  end
end
# rubocop:enable RSpec/MultipleDescribes
