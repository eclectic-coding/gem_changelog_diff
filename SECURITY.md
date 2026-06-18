# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a Vulnerability

If you discover a security vulnerability in gem_changelog_diff, please report it responsibly.

**Email:** chuck@eclecticcoding.com

Please include:

- A description of the vulnerability
- Steps to reproduce the issue
- The potential impact

**Expected response time:** You should receive an acknowledgment within 48 hours. A fix or mitigation plan will be communicated within 7 days.

## Scope

Security issues relevant to this gem include:

- Command injection via gem names or user-supplied arguments
- Credential leakage (GitHub tokens in logs, cached responses, or error messages)
- Unsafe deserialization of cached data or API responses
- Path traversal in file operations (cache, config, output)

Issues related to the GitHub API, RubyGems API, or upstream dependencies should be reported to their respective maintainers.
