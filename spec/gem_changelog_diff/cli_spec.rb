# frozen_string_literal: true

RSpec.describe GemChangelogDiff::CLI do
  let(:rails_gem) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

  after { GemChangelogDiff.reset_configuration! }

  describe "#check" do
    context "when all gems are up to date" do
      it "prints up to date message" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [])
        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("All gems are up to date!")
      end
    end

    context "when gems are outdated with releases" do
      it "prints formatted changelog output" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
        rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
        source_resolver = instance_double(GemChangelogDiff::SourceResolver)

        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
        allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
        allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
        allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
        allow(source_resolver).to receive(:resolve)
          .with("rails/rails", "7.0.8", "7.1.3")
          .and_return([{ tag_name: "v7.1.3", name: "7.1.3",
                         published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" }])

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("== rails (7.0.8 → 7.1.3) ==")
        expect(output).to include("Bug fixes")
      end
    end

    context "when a gem has no GitHub repository" do
      it "prints an error message for that gem" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
        rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
        allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
        allow(rubygems_client).to receive(:repo_url).with("rails").and_return(nil)

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("Could not find GitHub repository.")
      end
    end

    context "when a gem raises an error" do
      it "skips the gem and includes the error in output" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
        rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
        allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
        allow(rubygems_client).to receive(:repo_url)
          .and_raise(GemChangelogDiff::NetworkError, "connection refused")

        output = capture_output { described_class.start(["check"]) }

        expect(output).to include("connection refused")
      end

      it "warns to stderr" do
        detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
        rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
        allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
        allow(rubygems_client).to receive(:repo_url)
          .and_raise(GemChangelogDiff::NetworkError, "connection refused")

        expect { capture_output { described_class.start(["check"]) } }
          .to output(/Skipping rails/).to_stderr
      end
    end
  end

  describe "--verbose flag" do
    it "prints status messages to stderr" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
      allow(source_resolver).to receive(:resolve).and_return([])

      expect { capture_output { described_class.start(["check", "--verbose"]) } }
        .to output(/Checking rails/).to_stderr
    end
  end

  describe "--no-color flag" do
    it "disables colored output" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
      allow(source_resolver).to receive(:resolve).and_return([])

      output = capture_output { described_class.start(["check", "--no-color"]) }

      expect(output).not_to include("\e[")
    end
  end

  describe "--quiet flag" do
    it "suppresses warning output to stderr" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url)
        .and_raise(GemChangelogDiff::NetworkError, "connection refused")

      expect { capture_output { described_class.start(["check", "--quiet"]) } }
        .not_to output.to_stderr
    end
  end

  describe "--token flag" do
    it "sets the GitHub token from the flag" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      capture_output { described_class.start(["check", "--token", "ghp_flag_token"]) }

      expect(GemChangelogDiff.configuration.github_token).to eq("ghp_flag_token")
    end

    it "falls back to GITHUB_TOKEN env var" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("GITHUB_TOKEN", nil).and_return("ghp_env_token")

      capture_output { described_class.start(["check"]) }

      expect(GemChangelogDiff.configuration.github_token).to eq("ghp_env_token")
    end
  end

  describe ".exit_on_failure?" do
    it "returns true" do
      expect(described_class.exit_on_failure?).to be true
    end
  end

  describe "#version" do
    it "prints the version" do
      output = capture_output { described_class.start(["version"]) }

      expect(output).to include("gem_changelog_diff #{GemChangelogDiff::VERSION}")
    end
  end

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end