# frozen_string_literal: true

module GemChangelogDiff
  # Raised when a gem's source repository cannot be found on GitHub.
  class RepoNotFoundError < Error; end

  # Raised when the GitHub API returns an unexpected error response.
  class GitHubAPIError < Error; end

  # Raised when the GitHub API rate limit is exceeded.
  class RateLimitError < GitHubAPIError; end

  # Raised on HTTP connection failures (timeouts, DNS, SSL).
  class NetworkError < Error; end
end
