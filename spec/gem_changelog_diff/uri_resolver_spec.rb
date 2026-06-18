# frozen_string_literal: true

RSpec.describe GemChangelogDiff::UriResolver do
  let(:resolver) { described_class.new }

  before do
    stub_request(:head, %r{api\.github\.com/repos/}).to_return(status: 200)
  end

  describe "#resolve" do
    context "with a GitHub source_code_uri" do
      it "returns owner/repo" do
        data = { "source_code_uri" => "https://github.com/rails/rails" }

        expect(resolver.resolve(data)).to eq("rails/rails")
      end
    end

    context "with a GitHub homepage_uri fallback" do
      it "returns owner/repo from homepage" do
        data = {
          "source_code_uri" => nil,
          "homepage_uri" => "https://github.com/sinatra/sinatra"
        }

        expect(resolver.resolve(data)).to eq("sinatra/sinatra")
      end
    end

    context "with a GitHub bug_tracker_uri fallback" do
      it "returns owner/repo from bug tracker" do
        data = {
          "source_code_uri" => nil,
          "homepage_uri" => nil,
          "bug_tracker_uri" => "https://github.com/rspec/rspec/issues"
        }

        expect(resolver.resolve(data)).to eq("rspec/rspec")
      end
    end

    context "with a .git suffix" do
      it "strips the .git suffix" do
        data = { "source_code_uri" => "https://github.com/owner/repo.git" }

        expect(resolver.resolve(data)).to eq("owner/repo")
      end
    end

    context "with a monorepo subdirectory URI" do
      it "strips the path after owner/repo" do
        data = { "source_code_uri" => "https://github.com/rails/rails/tree/main/activerecord" }

        expect(resolver.resolve(data)).to eq("rails/rails")
      end
    end

    context "with a GitLab source URI" do
      it "raises RepoNotFoundError" do
        data = { "source_code_uri" => "https://gitlab.com/owner/repo" }

        expect { resolver.resolve(data) }.to raise_error(
          GemChangelogDiff::RepoNotFoundError, /GitLab/
        )
      end
    end

    context "with a Codeberg source URI" do
      it "raises RepoNotFoundError" do
        data = { "source_code_uri" => "https://codeberg.org/owner/repo" }

        expect { resolver.resolve(data) }.to raise_error(
          GemChangelogDiff::RepoNotFoundError, /Codeberg/
        )
      end
    end

    context "with a Bitbucket source URI" do
      it "raises RepoNotFoundError" do
        data = { "source_code_uri" => "https://bitbucket.org/owner/repo" }

        expect { resolver.resolve(data) }.to raise_error(
          GemChangelogDiff::RepoNotFoundError, /Bitbucket/
        )
      end
    end

    context "with a SourceHut URI" do
      it "raises RepoNotFoundError" do
        data = { "source_code_uri" => "https://git.sr.ht/~owner/repo" }

        expect { resolver.resolve(data) }.to raise_error(
          GemChangelogDiff::RepoNotFoundError, /SourceHut/
        )
      end
    end

    context "with no source URIs" do
      it "returns nil" do
        data = { "source_code_uri" => nil, "homepage_uri" => nil, "bug_tracker_uri" => nil }

        expect(resolver.resolve(data)).to be_nil
      end
    end

    context "with all empty string URIs" do
      it "returns nil" do
        data = { "source_code_uri" => "", "homepage_uri" => "  ", "bug_tracker_uri" => "" }

        expect(resolver.resolve(data)).to be_nil
      end
    end

    context "with an invalid URI" do
      it "skips the invalid URI gracefully" do
        data = { "source_code_uri" => "not a valid uri %%", "homepage_uri" => "https://github.com/owner/repo" }

        expect(resolver.resolve(data)).to eq("owner/repo")
      end
    end

    context "when a renamed repo returns a redirect" do
      it "follows the redirect to the new slug" do
        stub_request(:head, "https://api.github.com/repos/old-owner/old-repo")
          .to_return(status: 301, headers: { "Location" => "https://api.github.com/repos/new-owner/new-repo" })
        stub_request(:head, "https://api.github.com/repos/new-owner/new-repo")
          .to_return(status: 200)

        data = { "source_code_uri" => "https://github.com/old-owner/old-repo" }

        expect(resolver.resolve(data)).to eq("new-owner/new-repo")
      end
    end

    context "when redirect check fails with a network error" do
      it "returns the original slug" do
        stub_request(:head, "https://api.github.com/repos/owner/repo")
          .to_raise(SocketError.new("connection failed"))

        data = { "source_code_uri" => "https://github.com/owner/repo" }

        expect(resolver.resolve(data)).to eq("owner/repo")
      end
    end

    context "when max redirects are exceeded" do
      it "returns the last known slug" do
        stub_request(:head, "https://api.github.com/repos/loop/repo")
          .to_return(status: 301, headers: { "Location" => "https://api.github.com/repos/loop/repo" })

        data = { "source_code_uri" => "https://github.com/loop/repo" }

        expect(resolver.resolve(data)).to eq("loop/repo")
      end
    end

    context "when repo is not redirected" do
      it "returns the original slug" do
        data = { "source_code_uri" => "https://github.com/owner/repo" }

        expect(resolver.resolve(data)).to eq("owner/repo")
      end
    end
  end
end
