# frozen_string_literal: true

module GemChangelogDiff
  class RepoNotFoundError < Error; end
  class GitHubAPIError < Error; end
  class RateLimitError < GitHubAPIError; end
  class NetworkError < Error; end
end
