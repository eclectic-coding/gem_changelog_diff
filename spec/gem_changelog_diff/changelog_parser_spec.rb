# frozen_string_literal: true

RSpec.describe GemChangelogDiff::ChangelogParser do
  subject(:parser) { described_class.new }

  after { GemChangelogDiff.reset_configuration! }

  let(:contents_url) { "https://api.github.com/repos/owner/repo/contents/" }

  let(:keep_a_changelog) do
    <<~CHANGELOG
      # Changelog

      ## [Unreleased]

      ## [2.0.0] - 2024-03-01

      ### Added
      - New feature X

      ### Changed
      - Breaking change Y

      ## [1.1.0] - 2024-01-15

      ### Fixed
      - Bug fix Z

      ## [1.0.0] - 2023-06-01

      ### Added
      - Initial release
    CHANGELOG
  end

  def stub_contents(filename, content)
    stub_request(:get, "#{contents_url}#{filename}")
      .to_return(status: 200, body: { "content" => [content].pack("m") }.to_json)
  end

  def stub_not_found(filename)
    stub_request(:get, "#{contents_url}#{filename}")
      .to_return(status: 404, body: "Not Found")
  end

  describe "#entries_between" do
    context "with a Keep-a-Changelog format" do
      it "returns entries between versions" do
        stub_contents("CHANGELOG.md", keep_a_changelog)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries.map { |e| e[:tag_name] }).to eq(%w[2.0.0 1.1.0])
      end

      it "excludes the current version" do
        stub_contents("CHANGELOG.md", keep_a_changelog)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries.map { |e| e[:tag_name] }).not_to include("1.0.0")
      end

      it "includes the body content" do
        stub_contents("CHANGELOG.md", keep_a_changelog)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries.first[:body]).to include("New feature X")
      end

      it "returns release_hash format with nil published_at" do
        stub_contents("CHANGELOG.md", keep_a_changelog)

        entry = parser.entries_between("owner/repo", "1.0.0", "2.0.0").first

        expect(entry).to include(tag_name: "2.0.0", name: "2.0.0", published_at: nil)
      end
    end

    context "with filename fallback" do
      it "tries CHANGES.md when CHANGELOG.md is not found" do
        stub_not_found("CHANGELOG.md")
        stub_contents("CHANGES.md", keep_a_changelog)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries).not_to be_empty
      end

      it "tries History.md and NEWS.md" do
        stub_not_found("CHANGELOG.md")
        stub_not_found("CHANGES.md")
        stub_not_found("History.md")
        stub_not_found("NEWS.md")

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries).to eq([])
      end
    end

    context "with headings without brackets" do
      it "parses bare version headings" do
        content = <<~CHANGELOG
          # Changelog

          ## 2.0.0

          - New stuff

          ## 1.0.0

          - Old stuff
        CHANGELOG

        stub_contents("CHANGELOG.md", content)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries.size).to eq(1)
        expect(entries.first[:tag_name]).to eq("2.0.0")
      end
    end

    context "with malformed version in heading" do
      it "skips entries with invalid versions" do
        content = <<~CHANGELOG
          # Changelog

          ## [2.0.0] - 2024-03-01

          - New stuff

          ## [not-a-version]

          - Bad entry

          ## [1.0.0] - 2023-06-01

          - Old stuff
        CHANGELOG

        stub_contents("CHANGELOG.md", content)

        entries = parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(entries.size).to eq(1)
        expect(entries.first[:tag_name]).to eq("2.0.0")
      end
    end

    context "with invalid version arguments" do
      it "returns empty array when current version is malformed" do
        stub_contents("CHANGELOG.md", keep_a_changelog)

        entries = parser.entries_between("owner/repo", "not a version", "2.0.0")

        expect(entries).to eq([])
      end
    end

    context "when Errno::ETIMEDOUT occurs" do
      it "raises NetworkError" do
        stub_request(:get, "#{contents_url}CHANGELOG.md")
          .to_raise(Errno::ETIMEDOUT)

        expect { parser.entries_between("owner/repo", "1.0.0", "2.0.0") }
          .to raise_error(GemChangelogDiff::NetworkError)
      end
    end

    context "when OpenSSL::SSL::SSLError occurs" do
      it "raises NetworkError" do
        stub_request(:get, "#{contents_url}CHANGELOG.md")
          .to_raise(OpenSSL::SSL::SSLError.new("SSL error"))

        expect { parser.entries_between("owner/repo", "1.0.0", "2.0.0") }
          .to raise_error(GemChangelogDiff::NetworkError)
      end
    end

    context "when no changelog file exists" do
      it "returns an empty array" do
        stub_not_found("CHANGELOG.md")
        stub_not_found("CHANGES.md")
        stub_not_found("History.md")
        stub_not_found("NEWS.md")

        expect(parser.entries_between("owner/repo", "1.0.0", "2.0.0")).to eq([])
      end
    end

    context "when a network error occurs" do
      it "raises NetworkError" do
        stub_request(:get, "#{contents_url}CHANGELOG.md")
          .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

        expect { parser.entries_between("owner/repo", "1.0.0", "2.0.0") }
          .to raise_error(GemChangelogDiff::NetworkError)
      end
    end

    context "with a GitHub token configured" do
      it "sends the Authorization header" do
        GemChangelogDiff.configuration.github_token = "ghp_test"
        stub_contents("CHANGELOG.md", keep_a_changelog)

        parser.entries_between("owner/repo", "1.0.0", "2.0.0")

        expect(WebMock).to have_requested(:get, "#{contents_url}CHANGELOG.md")
          .with(headers: { "Authorization" => "token ghp_test" })
      end
    end
  end
end
