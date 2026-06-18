# frozen_string_literal: true

RSpec.describe GemChangelogDiff::ExitCode do
  it "defines SUCCESS as 0" do
    expect(described_class::SUCCESS).to eq(0)
  end

  it "defines ERROR as 1" do
    expect(described_class::ERROR).to eq(1)
  end

  it "defines PARTIAL_FAILURE as 2" do
    expect(described_class::PARTIAL_FAILURE).to eq(2)
  end
end
