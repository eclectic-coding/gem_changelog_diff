# frozen_string_literal: true

RSpec.describe GemChangelogDiff do
  it "has a version number" do
    expect(GemChangelogDiff::VERSION).not_to be_nil
  end
end
