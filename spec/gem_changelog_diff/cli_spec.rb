# frozen_string_literal: true

RSpec.describe GemChangelogDiff::CLI do
  let(:rails_gem) do
    GemChangelogDiff::OutdatedGem.new(name: "rails", current_version: "7.0.8", newest_version: "7.1.3")
  end

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
        github_client = instance_double(GemChangelogDiff::GithubClient)

        allow(GemChangelogDiff::Detector).to receive(:new).and_return(detector)
        allow(GemChangelogDiff::RubygemsClient).to receive(:new).and_return(rubygems_client)
        allow(GemChangelogDiff::GithubClient).to receive(:new).and_return(github_client)
        allow(rubygems_client).to receive(:repo_url).with("rails").and_return("rails/rails")
        allow(github_client).to receive(:releases_between)
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