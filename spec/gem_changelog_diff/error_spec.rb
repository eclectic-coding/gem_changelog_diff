# frozen_string_literal: true

RSpec.describe GemChangelogDiff::Error do
  it "RepoNotFoundError inherits from Error" do
    expect(GemChangelogDiff::RepoNotFoundError).to be < described_class
  end

  it "GitHubAPIError inherits from Error" do
    expect(GemChangelogDiff::GitHubAPIError).to be < described_class
  end

  it "RateLimitError inherits from GitHubAPIError" do
    expect(GemChangelogDiff::RateLimitError).to be < GemChangelogDiff::GitHubAPIError
  end

  it "NetworkError inherits from Error" do
    expect(GemChangelogDiff::NetworkError).to be < described_class
  end
end
