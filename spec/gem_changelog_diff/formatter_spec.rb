# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Formatter do
  it "is an alias for Formatters::Text" do
    expect(described_class).to eq(GemChangelogDiff::Formatters::Text)
  end

  it "can be instantiated with the same interface" do
    formatter = described_class.new(color: false)

    expect(formatter).to be_a(GemChangelogDiff::Formatters::Text)
  end
end
