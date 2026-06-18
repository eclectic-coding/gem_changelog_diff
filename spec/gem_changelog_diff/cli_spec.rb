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

  describe "--strategy lockfile" do
    it "uses lockfile parser instead of bundle outdated" do
      lockfile_parser = instance_double(GemChangelogDiff::LockfileParser, detect: [])
      allow(GemChangelogDiff::LockfileParser).to receive(:new).and_return(lockfile_parser)

      capture_output { described_class.start(["check", "--strategy", "lockfile"]) }

      expect(lockfile_parser).to have_received(:detect).with(lockfile_path: "Gemfile.lock")
    end
  end

  describe "--strategy outdated" do
    it "uses bundle outdated only" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      capture_output { described_class.start(["check", "--strategy", "outdated"]) }

      expect(detector).to have_received(:detect)
    end
  end

  describe "--strategy auto" do
    it "falls back to lockfile when bundle outdated fails" do
      detector = instance_double(GemChangelogDiff::Detector)
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(detector).to receive(:detect).and_raise(GemChangelogDiff::Error, "bundle outdated failed")

      lockfile_parser = instance_double(GemChangelogDiff::LockfileParser, detect: [])
      allow(GemChangelogDiff::LockfileParser).to receive(:new).and_return(lockfile_parser)

      capture_output { described_class.start(["check"]) }

      expect(lockfile_parser).to have_received(:detect)
    end
  end

  describe "--lockfile flag" do
    it "passes custom path to lockfile parser" do
      lockfile_parser = instance_double(GemChangelogDiff::LockfileParser, detect: [])
      allow(GemChangelogDiff::LockfileParser).to receive(:new).and_return(lockfile_parser)

      capture_output { described_class.start(["check", "--strategy", "lockfile", "--lockfile", "/custom/path"]) }

      expect(lockfile_parser).to have_received(:detect).with(lockfile_path: "/custom/path")
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

  describe "positional gem args" do
    it "filters to only named gems" do
      sidekiq_gem = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                      newest_version: "7.2.0")
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem, sidekiq_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      source_resolver = instance_double(GemChangelogDiff::SourceResolver)
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).and_return(nil)

      output = capture_output { described_class.start(["check", "rails"]) }

      expect(output).to include("rails")
      expect(output).not_to include("sidekiq")
    end
  end

  describe "--ignore flag" do
    it "excludes ignored gems" do
      sidekiq_gem = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                      newest_version: "7.2.0")
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem, sidekiq_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      source_resolver = instance_double(GemChangelogDiff::SourceResolver)
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).and_return(nil)

      output = capture_output { described_class.start(["check", "--ignore", "rails"]) }

      expect(output).not_to include("rails")
      expect(output).to include("sidekiq")
    end
  end

  describe "--group flag" do
    it "passes group to Detector" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).with(group: "development").and_return(detector)

      capture_output { described_class.start(["check", "--group", "development"]) }

      expect(GemChangelogDiff::Detector).to have_received(:new).with(group: "development")
    end
  end

  describe "progress spinner" do
    before { require "tty-spinner" }

    it "shows spinner when stderr is a tty" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).and_return(nil)
      allow($stderr).to receive(:tty?).and_return(true)

      spinner = instance_double(TTY::Spinner)
      allow(TTY::Spinner).to receive(:new).and_return(spinner)
      allow(spinner).to receive(:auto_spin)
      allow(spinner).to receive(:stop)

      capture_output { described_class.start(["check"]) }

      expect(spinner).to have_received(:auto_spin)
      expect(spinner).to have_received(:stop).with("Done!")
    end
  end

  describe "#cache" do
    it "clears the cache" do
      cache_instance = instance_double(GemChangelogDiff::Cache)
      allow(GemChangelogDiff::Cache).to receive(:new).and_return(cache_instance)
      allow(cache_instance).to receive(:clear)

      output = capture_output { described_class.start(["cache", "clear"]) }

      expect(output).to include("Cache cleared.")
      expect(cache_instance).to have_received(:clear)
    end

    it "shows usage for unknown subcommand" do
      output = capture_output { described_class.start(["cache"]) }

      expect(output).to include("Usage:")
    end
  end

  describe "--format json" do
    it "outputs valid JSON" do
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

      output = capture_output { described_class.start(["check", "--format", "json"]) }

      parsed = JSON.parse(output)
      expect(parsed["gems"].first["gem"]["name"]).to eq("rails")
    end
  end

  describe "--format markdown" do
    it "outputs markdown headings" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
      allow(source_resolver).to receive(:resolve).and_return([])

      output = capture_output { described_class.start(["check", "--format", "markdown"]) }

      expect(output).to include("## rails (7.0.8 → 7.1.3)")
    end
  end

  describe "--output flag" do
    it "writes output to a file" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return(nil)

      require "tempfile"
      tmpfile = Tempfile.new("changelog_output")
      begin
        output = capture_output { described_class.start(["check", "--output", tmpfile.path]) }

        expect(output).to include("Output written to")
        expect(File.read(tmpfile.path)).to include("rails")
      ensure
        tmpfile.close
        tmpfile.unlink
      end
    end
  end

  describe "--interactive flag" do
    it "presents interactive selection and filters gems" do
      sidekiq_gem = GemChangelogDiff::OutdatedGem.new(name: "sidekiq", current_version: "7.1.0",
                                                      newest_version: "7.2.0")
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem, sidekiq_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      interactive = instance_double(GemChangelogDiff::Interactive)
      allow(GemChangelogDiff::Interactive).to receive(:new).and_return(interactive)
      allow(interactive).to receive(:select).and_return([rails_gem])

      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).and_return(nil)

      output = capture_output { described_class.start(["check", "--interactive"]) }

      expect(output).to include("rails")
      expect(output).not_to include("sidekiq")
    end

    it "prints message when no gems selected" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      interactive = instance_double(GemChangelogDiff::Interactive)
      allow(GemChangelogDiff::Interactive).to receive(:new).and_return(interactive)
      allow(interactive).to receive(:select).and_return([])

      output = capture_output { described_class.start(["check", "--interactive"]) }

      expect(output).to include("No gems selected.")
    end
  end

  describe "#show" do
    it "shows changelog for a specific gem" do
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
      allow(source_resolver).to receive(:resolve)
        .with("rails/rails", "7.0.8", "7.1.3")
        .and_return([{ tag_name: "v7.1.3", name: "7.1.3",
                       published_at: "2024-02-21T00:00:00Z", body: "Bug fixes" }])

      output = capture_output { described_class.start(["show", "rails", "7.0.8", "7.1.3"]) }

      expect(output).to include("rails (7.0.8 → 7.1.3)")
      expect(output).to include("Bug fixes")
    end

    it "shows error when repo not found" do
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).with("mygem").and_return(nil)

      output = capture_output { described_class.start(["show", "mygem", "1.0.0", "2.0.0"]) }

      expect(output).to include("Could not find GitHub repository.")
    end

    it "supports --format json" do
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)
      source_resolver = instance_double(GemChangelogDiff::SourceResolver)

      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(GemChangelogDiff::SourceResolver).to receive(:new).and_return(source_resolver)
      allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
      allow(source_resolver).to receive(:resolve).and_return([])

      output = capture_output { described_class.start(["show", "rails", "7.0.8", "7.1.3", "--format", "json"]) }

      parsed = JSON.parse(output)
      expect(parsed["gems"].first["gem"]["name"]).to eq("rails")
    end
  end

  describe "#init" do
    it "creates a config file" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          capture_output { described_class.start(["init"]) }

          expect(File.exist?(".gem_changelog_diff.yml")).to be true
          expect(File.read(".gem_changelog_diff.yml")).to include("gem_changelog_diff configuration")
        end
      end
    end

    it "skips if config file already exists" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          File.write(".gem_changelog_diff.yml", "existing: true")

          output = capture_output { described_class.start(["init"]) }

          expect(output).to include("already exists")
          expect(File.read(".gem_changelog_diff.yml")).to eq("existing: true")
        end
      end
    end
  end

  describe "config file loading" do
    it "applies config file settings" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      rubygems_client = instance_double(GemChangelogDiff::RubygemsClient)

      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
      allow(rubygems_client).to receive(:repo_url).and_return(nil)

      config_loader = instance_double(GemChangelogDiff::ConfigLoader)
      allow(GemChangelogDiff::ConfigLoader).to receive(:new).and_return(config_loader)
      allow(config_loader).to receive(:load).and_return({ ignore_gems: ["rails"] })

      output = capture_output { described_class.start(["check"]) }

      expect(output).to include("All gems are up to date!")
    end
  end

  describe "--dry-run flag" do
    it "lists gems without fetching changelogs" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      output = capture_output { described_class.start(["check", "--dry-run"]) }

      expect(output).to include("rails (7.0.8 → 7.1.3)")
    end

    it "does not call RubygemsClient" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
      allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_call_original

      capture_output { described_class.start(["check", "--dry-run"]) }

      expect(GemChangelogDiff::RubygemsClient).not_to have_received(:new)
    end

    it "outputs JSON with --format json" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      output = capture_output { described_class.start(["check", "--dry-run", "--format", "json"]) }

      parsed = JSON.parse(output)
      expect(parsed.first["name"]).to eq("rails")
    end

    it "outputs markdown with --format markdown" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [rails_gem])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      output = capture_output { described_class.start(["check", "--dry-run", "--format", "markdown"]) }

      expect(output).to include("- **rails** (7.0.8 → 7.1.3)")
    end
  end

  describe "Rails credentials token" do
    it "reads token from Rails credentials when available" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      credentials = double("credentials")
      allow(credentials).to receive(:dig).with(:gem_changelog_diff, :github_token).and_return("ghp_rails_token")

      application = double("application", credentials: credentials)
      allow(application).to receive(:respond_to?).with(:credentials).and_return(true)

      rails_module = double("Rails", application: application)
      stub_const("Rails", rails_module)

      capture_output { described_class.start(["check"]) }

      expect(GemChangelogDiff.configuration.github_token).to eq("ghp_rails_token")
    end

    it "returns nil gracefully when not in Rails" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      capture_output { described_class.start(["check"]) }

      expect(GemChangelogDiff.configuration.github_token).to be_nil
    end

    it "returns nil when Rails credentials raises an error" do
      detector = instance_double(GemChangelogDiff::Detector, detect: [])
      allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)

      credentials = double("credentials")
      allow(credentials).to receive(:dig).and_raise(StandardError, "credentials error")

      application = double("application", credentials: credentials)
      allow(application).to receive(:respond_to?).with(:credentials).and_return(true)

      rails_module = double("Rails", application: application)
      stub_const("Rails", rails_module)

      capture_output { described_class.start(["check"]) }

      expect(GemChangelogDiff.configuration.github_token).to be_nil
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