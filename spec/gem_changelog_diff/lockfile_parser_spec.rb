# frozen_string_literal: true

RSpec.describe GemChangelogDiff::LockfileParser do
  subject(:parser) { described_class.new(rubygems_client: rubygems_client) }

  let(:rubygems_client) { instance_double(GemChangelogDiff::RubygemsClient) }
  let(:lockfile_content) do
    <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rails (7.0.8)
          sidekiq (7.1.0)
          rake (13.0.6)

      PLATFORMS
        ruby

      DEPENDENCIES
        rails
        sidekiq
        rake

      BUNDLED WITH
        2.5.0
    LOCKFILE
  end

  describe "#detect" do
    context "with outdated gems" do
      it "returns outdated gems" do
        allow(File).to receive(:read).with("Gemfile.lock").and_return(lockfile_content)
        allow(rubygems_client).to receive(:latest_version).with("rails").and_return("7.1.3")
        allow(rubygems_client).to receive(:latest_version).with("sidekiq").and_return("7.2.0")
        allow(rubygems_client).to receive(:latest_version).with("rake").and_return("13.0.6")

        gems = parser.detect

        expect(gems.map(&:name)).to contain_exactly("rails", "sidekiq")
      end
    end

    context "when all gems are up to date" do
      it "returns an empty array" do
        allow(File).to receive(:read).with("Gemfile.lock").and_return(lockfile_content)
        allow(rubygems_client).to receive(:latest_version).with("rails").and_return("7.0.8")
        allow(rubygems_client).to receive(:latest_version).with("sidekiq").and_return("7.1.0")
        allow(rubygems_client).to receive(:latest_version).with("rake").and_return("13.0.6")

        expect(parser.detect).to eq([])
      end
    end

    context "when a gem is not found on RubyGems" do
      it "skips that gem" do
        allow(File).to receive(:read).with("Gemfile.lock").and_return(lockfile_content)
        allow(rubygems_client).to receive(:latest_version).with("rails").and_return(nil)
        allow(rubygems_client).to receive(:latest_version).with("sidekiq").and_return("7.2.0")
        allow(rubygems_client).to receive(:latest_version).with("rake").and_return("13.0.6")

        gems = parser.detect

        expect(gems.map(&:name)).to eq(["sidekiq"])
      end
    end

    context "with a custom lockfile path" do
      it "reads from the specified path" do
        allow(File).to receive(:read).with("/custom/Gemfile.lock").and_return(lockfile_content)
        allow(rubygems_client).to receive(:latest_version).and_return(nil)

        parser.detect(lockfile_path: "/custom/Gemfile.lock")

        expect(File).to have_received(:read).with("/custom/Gemfile.lock")
      end
    end

    context "when lockfile does not exist" do
      it "raises an error" do
        allow(File).to receive(:read).with("Gemfile.lock").and_raise(Errno::ENOENT)

        expect { parser.detect }.to raise_error(GemChangelogDiff::Error, /Lockfile not found/)
      end
    end

    context "with correct OutdatedGem fields" do
      it "sets current and newest versions" do
        allow(File).to receive(:read).with("Gemfile.lock").and_return(lockfile_content)
        allow(rubygems_client).to receive(:latest_version).with("rails").and_return("7.1.3")
        allow(rubygems_client).to receive(:latest_version).with("sidekiq").and_return("7.1.0")
        allow(rubygems_client).to receive(:latest_version).with("rake").and_return("13.0.6")

        gem = parser.detect.first

        expect(gem.name).to eq("rails")
        expect(gem.current_version).to eq("7.0.8")
        expect(gem.newest_version).to eq("7.1.3")
      end
    end
  end
end
