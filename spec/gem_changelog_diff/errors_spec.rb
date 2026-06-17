# frozen_string_literal: true

RSpec.describe "GemChangelogDiff error hierarchy" do
  it "RepoNotFoundError inherits from Error" do
    expect(GemChangelogDiff::RepoNotFoundError).to be < GemChangelogDiff::Error
  end

  it "GitHubAPIError inherits from Error" do
    expect(GemChangelogDiff::GitHubAPIError).to be < GemChangelogDiff::Error
  end

  it "RateLimitError inherits from GitHubAPIError" do
    expect(GemChangelogDiff::RateLimitError).to be < GemChangelogDiff::GitHubAPIError
  end

  it "NetworkError inherits from Error" do
    expect(GemChangelogDiff::NetworkError).to be < GemChangelogDiff::Error
  end
end
