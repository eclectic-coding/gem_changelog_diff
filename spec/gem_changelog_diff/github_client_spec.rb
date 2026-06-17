# frozen_string_literal: true

RSpec.describe GemChangelogDiff::GithubClient do
  subject(:client) { described_class.new }

  after { GemChangelogDiff.reset_configuration! }

  let(:releases_url) { "https://api.github.com/repos/rails/rails/releases?per_page=30" }

  let(:releases_json) do
    [
      { "tag_name" => "v7.1.3", "name" => "7.1.3", "published_at" => "2024-02-21T00:00:00Z",
        "body" => "Bug fixes" },
      { "tag_name" => "v7.1.2", "name" => "7.1.2", "published_at" => "2024-01-16T00:00:00Z",
        "body" => "Security patch" },
      { "tag_name" => "v7.1.1", "name" => "7.1.1", "published_at" => "2023-11-10T00:00:00Z",
        "body" => "Minor fixes" },
      { "tag_name" => "v7.1.0", "name" => "7.1.0", "published_at" => "2023-10-05T00:00:00Z",
        "body" => "Major release" },
      { "tag_name" => "v7.0.8", "name" => "7.0.8", "published_at" => "2023-09-01T00:00:00Z",
        "body" => "Old release" }
    ].to_json
  end

  describe "#releases_between" do
    context "with releases in range" do
      it "returns releases between current (exclusive) and newest (inclusive)" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        results = client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(results.map { |r| r[:tag_name] }).to eq(%w[v7.1.3 v7.1.2 v7.1.1 v7.1.0])
      end

      it "excludes the current version" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        results = client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(results.map { |r| r[:tag_name] }).not_to include("v7.0.8")
      end

      it "includes the newest version" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        results = client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(results.map { |r| r[:tag_name] }).to include("v7.1.3")
      end
    end

    context "when sorted" do
      it "returns releases sorted newest first" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        results = client.releases_between("rails/rails", "7.0.8", "7.1.3")
        versions = results.map { |r| r[:tag_name] }

        expect(versions).to eq(%w[v7.1.3 v7.1.2 v7.1.1 v7.1.0])
      end
    end

    context "with tags without v prefix" do
      it "handles bare version tags" do
        releases = [
          { "tag_name" => "2.0.0", "name" => "2.0.0", "published_at" => "2024-01-01T00:00:00Z",
            "body" => "New version" }
        ].to_json
        stub_request(:get, "https://api.github.com/repos/owner/repo/releases?per_page=30")
          .to_return(status: 200, body: releases)

        results = client.releases_between("owner/repo", "1.0.0", "2.0.0")

        expect(results.size).to eq(1)
        expect(results.first[:tag_name]).to eq("2.0.0")
      end
    end

    context "when no releases match" do
      it "returns an empty array" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        results = client.releases_between("rails/rails", "7.1.3", "7.1.4")

        expect(results).to eq([])
      end
    end

    context "when API returns 404" do
      it "returns an empty array" do
        stub_request(:get, releases_url).to_return(status: 404, body: "Not Found")

        results = client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(results).to eq([])
      end
    end

    context "with a GitHub token configured" do
      it "sends the Authorization header" do
        GemChangelogDiff.configuration.github_token = "ghp_test123"
        stub_request(:get, releases_url)
          .with(headers: { "Authorization" => "token ghp_test123" })
          .to_return(status: 200, body: releases_json)

        client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(WebMock).to have_requested(:get, releases_url)
          .with(headers: { "Authorization" => "token ghp_test123" })
      end
    end

    context "without a GitHub token" do
      it "does not send the Authorization header" do
        stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

        client.releases_between("rails/rails", "7.0.8", "7.1.3")

        expect(WebMock).to have_requested(:get, releases_url)
          .with { |req| req.headers.keys.none? { |k| k.casecmp("authorization").zero? } }
      end
    end

    context "when API returns 500" do
      it "raises GitHubAPIError" do
        stub_request(:get, releases_url).to_return(status: 500, body: "Internal Server Error")

        expect { client.releases_between("rails/rails", "7.0.8", "7.1.3") }
          .to raise_error(GemChangelogDiff::GitHubAPIError, /HTTP 500/)
      end
    end

    context "when rate limited" do
      it "raises RateLimitError" do
        stub_request(:get, releases_url)
          .to_return(status: 403, body: "Rate limit exceeded",
                     headers: { "X-RateLimit-Remaining" => "0" })

        expect { client.releases_between("rails/rails", "7.0.8", "7.1.3") }
          .to raise_error(GemChangelogDiff::RateLimitError, /rate limit exceeded/i)
      end
    end

    context "when rate limit is low" do
      it "warns to stderr" do
        stub_request(:get, releases_url)
          .to_return(status: 200, body: releases_json,
                     headers: { "X-RateLimit-Remaining" => "5" })

        expect { client.releases_between("rails/rails", "7.0.8", "7.1.3") }
          .to output(/rate limit low/i).to_stderr
      end
    end

    context "when a network error occurs" do
      it "raises NetworkError" do
        stub_request(:get, releases_url).to_raise(SocketError.new("getaddrinfo: Name or service not known"))

        expect { client.releases_between("rails/rails", "7.0.8", "7.1.3") }
          .to raise_error(GemChangelogDiff::NetworkError, /Name or service not known/)
      end
    end

    it "returns symbolized keys with expected fields" do
      stub_request(:get, releases_url).to_return(status: 200, body: releases_json)

      result = client.releases_between("rails/rails", "7.1.2", "7.1.3").first

      expect(result).to include(
        tag_name: "v7.1.3",
        name: "7.1.3",
        published_at: "2024-02-21T00:00:00Z",
        body: "Bug fixes"
      )
    end
  end
end